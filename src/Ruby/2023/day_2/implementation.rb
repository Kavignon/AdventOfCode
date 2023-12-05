# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

# Evaluates whether a ice ball game on snow island can specific colored ice balls.
module IceBagEvaluation
  extend T::Sig

  GAME_ID_REGEX = T.let(/Game (\d+):(.*)/, Regexp)
  INITIAL_COLOR_TO_MIN_COUNT = T.let({ blue: 0, red: 0, green: 0 }, T::Hash[Symbol, Integer])

  def self.ice_cube_acc_power(file_path)
    return 0 unless File.exist?(file_path)

    IO.foreach(file_path).map { |game_record| record_power_set(game_record) }.sum
  end

  sig { params(game_record: String).returns(Integer) }
  # Defines a method to parse the content of a game record and extract the game id when the game can be played.
  def self.record_power_set(game_record)
    match = game_record.match(GAME_ID_REGEX)
    return 0 unless match
    return 0 unless match.length >= 2

    game_sets = T.must(match[2]).split(';').map(&:strip)
    color_to_min_count = T.let(INITIAL_COLOR_TO_MIN_COUNT.dup, T.untyped)

    game_sets.each do |game_set|
      color_to_min_count = find_min_color_for_cubes(game_set, color_to_min_count)
    end

    T.must(color_to_min_count[:red]) * T.must(color_to_min_count[:green]) * color_to_min_count[:blue]
  end

  # Defines a method to evaluate whether a give game set of ice cube can be played on Snow Island.
  # @param [T::Array[String]] game_set
  # @return [T::Boolean]
  def self.find_min_color_for_cubes(game_set, color_to_min_count)
    cubes = game_set.split(',').map(&:strip)

    cubes.each do |cube|
      count, color = cube.split(' ')
      count = count.to_i
      color_to_min_count[color.to_sym] = [color_to_min_count[color.to_sym], count].max
    end

    color_to_min_count
  end
end

puts IceBagEvaluation.ice_cube_acc_power('src/input/2023/day_2.txt')
