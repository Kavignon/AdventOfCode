# frozen_string_literal: true
# typed: true

require "sorbet-runtime"

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

  NUMBER_WORDS = T.let(
    {
      'one' => 1, 'two' => 2, 'three' => 3, 'four' => 4, 'five' => 5,
      'six' => 6, 'seven' => 7, 'eight' => 8, 'nine' => 9
    }.freeze,
    T::Hash[String, Integer]
  )

  MAX_WORD_LENGTH_0_TO_9 = T.let(5, Integer)

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
    when 1 then readings.first.digit * 11
    else (readings.first.digit.to_s + readings.last.digit.to_s).to_i
    end
  end

  sig { params(line: String).returns(T::Array[CalibrationReading]) }
  def self.extract_readings(line)
    readings = []

    line.each_char.with_index do |char, i|
      if char.match?(/\d/)
        readings << CalibrationReading.new(i, char.to_i)
      else
        (1..MAX_WORD_LENGTH_0_TO_9).each do |len|
          window = line[i, len]
          spelled_out_number = window.downcase
          digit = NUMBER_WORDS[spelled_out_number]
          readings << CalibrationReading.new(i, digit) if digit
        end
      end
    end

    readings
  end
end

puts CalibrationDocument.launcher_calibration_value('src/input/2023/day_1.txt')
