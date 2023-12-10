# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

Schematics = T.type_alias { T::Array[T::Array[T.nilable(T.any(Integer, String))]] }

class String
  def i?
    !!(self =~ /\A[-+]?[0-9]+\z/)
  end
end

# Represents the plan of the engine.
class EngineSchematics
  extend T::Sig

  attr_reader :plan

  sig { params(engine_plan_str: String).void }
  def initialize(engine_plan_str)
    @plan = parse_plan(engine_plan_str)
  end

  private

  sig { params(str_grid: String).returns(Schematics) }
  def parse_plan(str_grid)
    raise StandardError, 'the grid is missing' if str_grid.nil? || str_grid.empty?

    str_grid.lines.map { |line| line.chomp.chars }
  end
end

# Handles processing the file containing the schematic engine plan.
module SchematicEngineSolver
  extend T::Sig

  SYMBOL_REGEX = T.let(/[[:punct:].]+/, Regexp)

  ADJACENT_POSITIONS =
    T.let([
      [0, -1], [1, 0], [0, -1], [0, 1], # Above, below, left, right
      [-1, -1], [-1, 1], [1, -1], [1, 1] # Diagonal positions
    ].freeze, T::Array[T::Array[Integer]])

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

    engine_schematics.plan.each_with_index do |row, row_index|
      col_index = 0

      while col_index < row.length
        engine_part_number, col_index = try_extract_engine_part_number(engine_schematics.plan, row_index, col_index)
        engine_plan_parts << engine_part_number unless engine_part_number.nil?
      end
    end

    engine_plan_parts.sum
  end

  sig do
    params(engine_schematics: Schematics, row_index: Integer, col_index: Integer).returns([T.nilable(Integer), Integer])
  end
  def self.try_extract_engine_part_number(engine_schematics, row_index, col_index)
    current_value = engine_schematics[row_index][col_index]
    next_to_symbol = number_adjacent_to_symbol?(engine_schematics, row_index, col_index)

    if digit?(current_value)
      next_col = col_index + 1
      engine_part_number = current_value.to_i

      while next_char_is_digit?(engine_schematics, row_index, next_col)
        engine_part_number = engine_part_number * 10 + engine_schematics[row_index][next_col].to_i
        next_to_symbol ||= number_adjacent_to_symbol?(engine_schematics, row_index, next_col)
        next_col += 1
      end

      next_to_symbol ? [engine_part_number, next_col] : [nil, next_col]
    else
      [nil, col_index + 1]
    end
  end

  # Checks if a number is adjacent to a symbol in the engine schematics.
  sig { params(engine_schematics: Schematics, row: Integer, col: Integer).returns(T::Boolean) }
  def self.number_adjacent_to_symbol?(engine_schematics, row, col)
    ADJACENT_POSITIONS.any? do |r_offset, c_offset|
      r = row + r_offset
      c = col + c_offset

      next false unless valid_position_and_symbol?(engine_schematics, r, c)

      engine_symbol?(engine_schematics[r][c])
    end
  end

  sig { params(engine_schematics: Schematics, row: Integer, col: Integer).returns(T::Boolean) }
  def self.valid_position_and_symbol?(engine_schematics, row, col)
    row.between?(0, engine_schematics.length - 1) &&
      col.between?(0, engine_schematics[0].length - 1) &&
      engine_symbol?(engine_schematics[row][col])
  end

  sig { params(engine_schematics: Schematics, row: Integer, col: Integer).returns(T::Boolean) }
  def self.next_char_is_digit?(engine_schematics, row, col)
    col < engine_schematics[row].length &&
      engine_schematics[row][col].i?
  end

  sig { params(engine_schematics: Schematics, row: Integer, col: Integer).returns(T::Boolean) }
  def self.digit_adjacent_to_symbol?(engine_schematics, row, col)
    ADJACENT_POSITIONS.any? do |r_offset, c_offset|
      r = row + r_offset
      c = col + c_offset

      next false unless r.between?(0, engine_schematics.length - 1) && c.between?(0, engine_schematics[0].length - 1)

      return true if engine_schematics[r][c].is_a?(String) && engine_symbol?(engine_schematics[r][c])
    end

    false
  end

  sig { params(engine_character: T.nilable(String)).returns(T::Boolean) }
  def self.digit?(engine_character)
    engine_character.i?
  end

  sig { params(engine_character: T.nilable(String)).returns(T::Boolean) }
  def self.engine_symbol?(engine_character)
    return false if engine_character.nil?

    engine_character.match?(SYMBOL_REGEX)
  end
end

puts SchematicEngineSolver.find_missing_engine_piece('src/input/2023/day_3.txt')
