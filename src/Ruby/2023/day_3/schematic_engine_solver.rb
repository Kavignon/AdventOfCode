# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'
require 'set'

Schematics = T.type_alias { T::Array[T::Array[T.nilable(T.any(Integer, String))]] }

class EngineSchematics
  extend T::Sig

  GRID_DIGIT_REGEX = T.let(/\d/, Regexp).freeze
  ENGINE_PART_NUM_AROUND_GEAR = T.let(2, Integer)
  ADJACENT_POSITIONS = T.let([
                               [-1, 0], [1, 0], [0, -1], [0, 1], # Above, below, left, right
                               [-1, -1], [-1, 1], [1, -1], [1, 1] # Diagonal positions
                             ].freeze, T::Array[T::Array[Integer]])

  attr_reader :engine_grid, :lift_engine_gears

  sig { params(engine_plan_str: String).void }
  def initialize(engine_plan_str)
    @engine_grid = parse_plan(engine_plan_str)
    @row_range = (0..@engine_grid.length - 1)
    @column_range = (0..@engine_grid[0].length - 1)
    @lift_engine_gears = extract_gears_from_plan(engine_plan_str)
  end

  private

  sig { params(row: Integer, col: Integer).returns(T::Array[Integer]) }
  def gondola_engine_gear_parts(row, col)
    gear_part_numbers = Set.new

    ADJACENT_POSITIONS.each do |r_offset, c_offset|
      updated_r = row + r_offset
      updated_c = col + c_offset

      next unless @row_range.cover?(updated_r) && @column_range.cover?(updated_c)
      next unless @engine_grid[updated_r][updated_c] =~ GRID_DIGIT_REGEX

      gear_part_numbers << collect_engine_number(updated_r, updated_c)
    end

    gear_part_numbers.to_a
  end

  sig { params(row: Integer, column: Integer).returns(Integer) }
  def collect_engine_number(row, column)
    part_number = ''
    initial_digit_index = find_number_first_digit_index(row, column)
    number_index = initial_digit_index

    until @engine_grid[row][number_index] !~ GRID_DIGIT_REGEX
      part_number += @engine_grid[row][number_index]
      number_index += 1
    end

    part_number.to_i
  end

  sig { params(row: Integer, column: Integer).returns(Integer) }
  def find_number_first_digit_index(row, column)
    current_column = column
    current_column -= 1 while current_column >= 0 && @engine_grid[row][current_column] =~ GRID_DIGIT_REGEX
    current_column + 1
  end

  sig { params(str_grid: String).returns(Schematics) }
  def parse_plan(str_grid)
    raise StandardError, 'the grid is missing or empty.' if str_grid.nil? || str_grid.empty?

    str_grid.lines.map { |line| line.chomp.chars }
  end

  sig { params(str_grid: String).returns(T::Array[Integer]) }
  def extract_gears_from_plan(str_grid)
    engine_gears = []

    str_grid.lines.each_with_index do |schematic_line, row_index|
      schematic_line.each_char.with_index do |_, col_index|
        next unless @engine_grid[row_index][col_index] == '*'

        gondola_gear_parts = gondola_engine_gear_parts(row_index, col_index)

        next unless gondola_gear_parts.size == ENGINE_PART_NUM_AROUND_GEAR

        engine_gears << T.must(gondola_gear_parts[0] * gondola_gear_parts[1])
      end
    end

    engine_gears
  end
end

module SchematicEngineSolver
  extend T::Sig

  sig { params(file_path: String).returns(Integer) }
  def self.find_missing_engine_piece(file_path)
    raise StandardError, "File not found: #{file_path}" unless File.exist?(file_path)

    engine_plan_content = File.read(file_path)
    raise StandardError, 'File content is empty' if engine_plan_content.empty?

    engine_schematics = EngineSchematics.new(engine_plan_content.lines.map(&:chomp).join("\n"))
    engine_schematics.lift_engine_gears.sum
  end
end

puts SchematicEngineSolver.find_missing_engine_piece('src/input/2023/day_3.txt')
