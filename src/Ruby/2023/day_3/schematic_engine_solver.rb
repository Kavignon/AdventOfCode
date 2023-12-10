# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

Schematics = T.type_alias { T::Array[T::Array[T.nilable(T.any(Integer, String))]] }
EngineLineSymbolCache = T.type_alias { T::Hash[RowIndex, T::Array[EngineLineSymbol]] }

# Define RowIndex as a struct
class RowIndex < T::Struct
  extend T::Sig

  const :value, Integer

  sig { params(other: ColumnIndex).returns(T::Boolean) }
  def less_than?(other)
    value < other.value
  end

  def between?(lower, upper)
    value.between?(lower, upper)
  end

  sig { params(other: Integer).returns(RowIndex) }
  def +(other)
    RowIndex.new(value: value + other)
  end

  # Override the == method to compare values
  sig { params(other: Object).returns(T::Boolean) }
  def ==(other)
    other.is_a?(RowIndex) && value == other.value
  end
end

# Define ColumnIndex as a struct
class ColumnIndex < T::Struct
  extend T::Sig

  const :value, Integer

  sig { params(other: T.any(ColumnIndex, Integer)).returns(T::Boolean) }
  def less_than?(other)
    other.is_a?(ColumnIndex) ? value < other.value : value < other
  end

  def between?(lower, upper)
    value.between?(lower, upper)
  end

  sig { params(other: Integer).returns(ColumnIndex) }
  def +(other)
    ColumnIndex.new(value: value + other)
  end

  # Override the == method to compare values
  sig { params(other: Object).returns(T::Boolean) }
  def ==(other)
    other.is_a?(ColumnIndex) && value == other.value
  end
end

class String
  def i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end

# Represents an encountered symbol within a line of an engine schematics plan.
class EngineLineSymbol
  extend T::Sig

  attr_reader :character, :occurrence_id

  sig { params(symbol_character: String, column_index: ColumnIndex).void}
  def initialize(symbol_character, column_index)
    @character = symbol_character
    @occurrence_id = column_index
  end
end

# Represents the plan of the engine.
class EngineSchematics
  extend T::Sig

  ADJACENT_POSITIONS = T.let([
    [-1, 0], [1, 0], [0, -1], [0, 1], # Above, below, left, right
    [-1, -1], [-1, 1], [1, -1], [1, 1] # Diagonal positions
  ].freeze, T::Array[T::Array[Integer]])

  attr_reader :engine_grid, :engine_cache

  sig { params(engine_plan_str: String).void }
  def initialize(engine_plan_str)
    @engine_grid = parse_plan(engine_plan_str)
    @engine_cache = extract_symbols_from_grid(engine_plan_str).reject { |_, symbols| symbols.empty? }
  end

  # Checks if a digit is adjacent to a symbol in the engine schematics.
  sig { params(row: RowIndex, col: ColumnIndex).returns(T::Boolean) }
  def digit_adjacent_to_symbol?(row, col)
    ADJACENT_POSITIONS.any? do |r_offset, c_offset|
      updated_r = row + r_offset
      updated_c = col + c_offset

      next false unless valid_position?(updated_r, updated_c)
      next if updated_r == row && updated_c == col

      engine_character = engine_grid[updated_r.value][updated_c.value]

      return true if engine_character != '.' && !engine_character.i?
    end

    false
  end

  sig { params(row: RowIndex, col: ColumnIndex).returns(T::Boolean) }
  def next_char_digit?(row, col)
    col.less_than?(@engine_grid[row.value].length) && @engine_grid[row.value][col.value].i?
  end

  private

  sig { params(str_grid: String).returns(Schematics) }
  def parse_plan(str_grid)
    raise StandardError, 'the grid is missing' if str_grid.nil? || str_grid.empty?

    str_grid.lines.map { |line| line.chomp.chars }
  end

  sig { params(str_grid: String).returns(EngineLineSymbolCache) }
  def extract_symbols_from_grid(str_grid)
    cache = {}
    str_grid.lines.each_with_index do |schematic_line, row_index|
      cache[row_index] ||= []
      schematic_line.each_char.with_index do |engine_char, col_index|
        next if engine_char.i? || engine_char == '.'

        cache[row_index] << EngineLineSymbol.new(engine_char, ColumnIndex.new(value: col_index))
      end
    end

    cache
  end

  sig { params(row: RowIndex, col: ColumnIndex).returns(T::Boolean) }
  def valid_position?(row, col)
    row.between?(0, engine_grid.length - 1) && col.between?(0, engine_grid[0].length - 1)
  end
end

# Handles processing the file containing the schematic engine plan.
module SchematicEngineSolver
  extend T::Sig

  sig { params(file_path: String).returns(Integer) }
  def self.find_missing_engine_piece(file_path)
    raise StandardError, "File not found: #{file_path}" unless File.exist?(file_path)

    engine_plan_content = File.read(file_path)
    raise StandardError, 'File content is empty' if engine_plan_content.empty?

    engine_schematics = EngineSchematics.new engine_plan_content.lines.map(&:chomp).join("\n")
    missing_part_number(engine_schematics)
  end

  sig { params(engine_schematics: EngineSchematics).returns(Integer) }
  def self.missing_part_number(engine_schematics)
    engine_plan_parts = []

    engine_schematics.engine_grid.each_with_index do |schematics_line, row_index|
      col_index = ColumnIndex.new(value: 0)
      row_index = RowIndex.new(value: row_index)

      while col_index.less_than?(schematics_line.length)
        engine_part_number, col_index = try_extract_engine_part_number(engine_schematics, row_index, col_index)
        engine_plan_parts << engine_part_number unless engine_part_number.nil?
      end
    end

    engine_plan_parts.sum
  end

  sig do
    params(engine_schematics: EngineSchematics, row_index: RowIndex,
           col_index: ColumnIndex).returns([T.nilable(Integer), ColumnIndex])
  end
  def self.try_extract_engine_part_number(engine_schematics, row_index, col_index)
    engine_grid = engine_schematics.engine_grid
    engine_character = engine_grid[row_index.value][col_index.value]
    next_to_symbol = engine_schematics.digit_adjacent_to_symbol?(row_index, col_index)

    if engine_character.i?
      next_col = col_index + 1
      engine_part_number = engine_character

      while engine_schematics.next_char_digit?(row_index, next_col)
        engine_part_number << engine_grid[row_index.value][next_col.value]
        next_to_symbol ||= engine_schematics.digit_adjacent_to_symbol?(row_index, next_col)
        next_col += 1
      end

      next_to_symbol ? [engine_part_number.to_i, next_col] : [nil, next_col]
    else
      [nil, col_index + 1]
    end
  end
end

puts SchematicEngineSolver.find_missing_engine_piece('src/input/2023/day_3.txt')
