# frozen_string_literal: true
# typed: false

# Represents a measurement in a calibration document.
class CalibrationReading
  extend T::Sig
  extend T::Generic

  Elem = type_member

  sig { params(index: Integer, digit: Elem).void }
  def initialize(index, digit)
    @index = index
    @digit = digit
  end

  sig { returns(Integer) }
  attr_reader :index

  sig { returns(Elem) }
  attr_reader :digit
end

# This module is responsible for handling the computation for the calibration system of the launcher.
# This serves to resolve the problem set by the Advent of Code 2023 day 1.
module CalibrationDocument
  extend T::Sig

  NUMBER_WORDS = T.let(
    {
      'one' => 1,
      'two' => 2,
      'three' => 3,
      'four' => 4,
      'five' => 5,
      'six' => 6,
      'seven' => 7,
      'eight' => 8,
      'nine' => 9
    }.freeze,
    T::Hash[String, Integer]
  )

  DIGITS_RANGE = T.let((0..9).freeze, T::Range[Integer])

  sig { params(file_path: String).returns(Integer) }
  def self.get_file_calibration_sum(file_path)
    return puts("File not found: #{file_path}") unless File.exist?(file_path)

    IO
      .foreach(file_path)
      .map { |line| collect_reading(line) }
      .sum
  end

  sig { params(calibration_line: String).returns(Integer) }
  def self.compute_calibration(calibration_line)
    return 0 if calibration_line.nil? || calibration_line.empty?

    readings = extract_digits_from_line(calibration_line)

    return 0 unless readings

    if readings.first && readings.last
      (readings.first.to_i * 10) + readings.last.to_i
    elsif readings.last.nil?
      (readings.first.to_i * 10) + readings.last.to_i
    else
      0
    end
  end

  sig { params(line: String).returns(Integer) }
  def self.collect_reading(line)
    digits_found_in_line = extract_digits_and_indexes(line)
    numbers_found_in_line = extract_digits_from_line(line)

    first_digit = digits_found_in_line.find do |digit1|
      numbers_found_in_line.any? do |digit2|
        digit1[:index] < digit2[:index]
      end
    end
    last_digit = digits_found_in_line.reverse.find do |digit1|
      numbers_found_in_line.any? do |digit2|
        digit1[:index] > digit2[:index]
      end
    end

    if first_digit && last_digit
      (first_digit[:digit].to_i * 10) + last_digit[:digit].to_i
    elsif last_digit.nil?
      (first_digit[:digit].to_i * 10) + first_digit[:digit].to_i
    else
      0
    end
  end

  sig { params(line: String).returns(T::Array[CalibrationReading[T.untyped]]) }
  def self.extract_digits_and_indexes(line)
    readings = []

    i = 0
    while i < line.length
      char = line[i]

      readings.push({ index: i, digit: char.to_i }) if ('0'..'9').cover?(char)

      i += 1
    end

    readings
  end

  sig { params(line: String).returns(T::Array[CalibrationReading[T.untyped]]) }
  def self.extract_digits_from_line(line)
    readings = []

    i = 0
    while i < line.length
      window_size = 5
      window = line[i, window_size]

      digit = convert_spelled_out_number(window)
      if digit
        index_of_letter_o = line.index('o', i) # Example, replace 'o' with the actual letter to find
        readings.push({ index: index_of_letter_o, digit: digit })
      end

      i += 1
    end

    readings
  end

  sig { params(spelled_out_number: String).returns(T.nilable(Integer)) }
  def self.convert_spelled_out_number(spelled_out_number)
    NUMBER_WORDS[spelled_out_number.downcase]
  end
end

puts CalibrationDocument.get_file_calibration_sum('input/2023/day_1.txt')
