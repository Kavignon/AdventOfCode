# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

# Evaluates whether a ice ball game on snow island can specific colored ice balls.
module IceBagEvaluation
  extend T::Sig

  GAME_ID_REGEX = T.let(/Game (\d+):(.*)/, Regexp)

  MAX_RED_BALLS = T.let(12, Integer)
  MAX_GREEN_BALLS = T.let(13, Integer)
  MAX_BLUE_BALLS = T.let(14, Integer)

  def self.ice_ball_game_sum(file_path)
    return 0 unless File.exist?(file_path)

    IO
      .foreach(file_path)
      .map { |game_record| ice_cube_game_id(game_record) }
      .sum
  end

  sig { params(game_record: String).returns(Integer) }
  # Defines a method to parse the content of a game record and extract the game id when the game can be played.
  def self.ice_cube_game_id(game_record)
    match = game_record.match(GAME_ID_REGEX)
    return unless match
    return unless match.length >= 2

    game_id = match[1].to_i
    game_sets = match[2].split(';').map(&:strip)

    game_sets.each do |game_set|
      next if ice_cube_set_valid?(game_set)

      return 0
    end

    game_id
  end

  # Defines a method to evaluate whether a give game set of ice cube can be played on Snow Island.
  # @param [T::Array[String]] game_set
  # @return [T::Boolean]
  def self.ice_cube_set_valid?(game_set)
    ice_cube_set_hash = { blue: 0, red: 0, green: 0 }

    game_set.split(',').map(&:strip).each do |ice_cube_set|
      count, color = ice_cube_set.split(' ')
      ice_cube_set_hash[color.to_sym] += count.to_i

      case
      when ice_cube_set_hash[:green] > MAX_GREEN_BALLS
        return false
      when ice_cube_set_hash[:blue] > MAX_BLUE_BALLS
        return false
      when ice_cube_set_hash[:red] > MAX_RED_BALLS
        return false
      else
        next
      end
    end

    true
  end
end

puts IceBagEvaluation.ice_ball_game_sum('src/input/2023/day_2.txt')
