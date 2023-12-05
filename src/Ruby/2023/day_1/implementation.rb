# frozen_string_literal: true
# typed: true

require 'sorbet-runtime'

# Represents a measurement in a calibration document.
class CalibrationReading
  extend ::T::Sig

  sig { params(index: Integer, digit: Integer).void }
  def initialize(index, digit)
    @index = index
    @digit = digit
  end

  sig { returns(Integer) }
  attr_reader :index

  sig { returns(Integer) }
  attr_reader :digit
end

# This module is responsible for handling the computation for the calibration system of the launcher.
# This serves to resolve the problem set by the Advent of Code 2023 day 1.
module CalibrationDocument
  extend T::Sig

  DIGIT_AS_WORDS = T.let(
    %w[zero one two three four five six seven eight nine].freeze,
    T::Array[String]
  )

  # Using a signature to specify the type of the block parameters
  WORD_TO_DIGIT = T.let(
    DIGIT_AS_WORDS.map.with_index { |word, index| [word, index] }.to_h.freeze,
    T::Hash[String, Integer]
  )

  MAX_WORD_LENGTH_0_TO_9 = T.let(5, Integer)
  DIGIT_AS_WORD_STR_RANGE = T.let((1..MAX_WORD_LENGTH_0_TO_9), T::Range[Integer])
  IS_DIGIT_REGEX = T.let(/\d/, Regexp)

  sig { params(file_path: String).returns(Integer) }
  def self.launcher_calibration_value(file_path)
    return 0 unless File.exist?(file_path)

    IO.foreach(file_path).map { |line| calibration_value(line) }.sum
  end

  sig { params(line: String).returns(Integer) }
  def self.calibration_value(line)
    readings = extract_readings(line)

    case readings.size
    when 0 then 0
    when 1 then T.must(readings.first).digit * 11
    else (T.must(readings.first).digit.to_s + T.must(readings.last).digit.to_s).to_i
    end
  end

  sig { params(line: String).returns(T::Array[CalibrationReading]) }
  def self.extract_readings(line)
    readings = []

    line.each_char.with_index do |char, i|
      if char.match?(IS_DIGIT_REGEX)
        readings << CalibrationReading.new(i, char.to_i)
      else
        DIGIT_AS_WORD_STR_RANGE.each do |len|
          window = line[i, len]
          spelled_out_number = T.must(window).downcase
          digit = WORD_TO_DIGIT[spelled_out_number]
          readings << CalibrationReading.new(i, digit) if digit
        end
      end
    end

    readings
  end
end

puts CalibrationDocument.launcher_calibration_value('src/input/2023/day_1.txt')
