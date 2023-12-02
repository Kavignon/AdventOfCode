# frozen_string_literal: true
# typed: true

module CalibrationDocument
  NUMBER_WORDS = {
    'one' => 1,
    'two' => 2,
    'three' => 3,
    'four' => 4,
    'five' => 5,
    'six' => 6,
    'seven' => 7,
    'eight' => 8,
    'nine' => 9
  }.freeze

  def self.get_file_calibration_sum(file_path)
    return puts("File not found: #{file_path}") unless File.exist?(file_path)

    IO
      .foreach(file_path)
      .map { |line| collect_reading(line) }
      .sum
  end

  def self.compute_calibration(calibration_line)
    return 0 if calibration_line.nil? || calibration_line.empty?

    readings = extract_digits_from_line(calibration_line)
    first = readings.first
    last = readings.last

    if first && last
      (first.to_i * 10) + last.to_i
    elsif last.nil?
      (first.to_i * 10) + first.to_i
    else
      0
    end
  end

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

  def self.convert_spelled_out_number(spelled_out_number)
    NUMBER_WORDS[spelled_out_number.downcase]
  end
end

puts CalibrationDocument.get_file_calibration_sum('input/2023/day_1.txt')
