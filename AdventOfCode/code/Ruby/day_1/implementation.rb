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
  }

  NUMBER_AS_DIGIT_OR_TEXT_REGEX = /\b(?:one|two|three|four|five|six|seven|eight|nine|\d+)\b|\d+|[a-zA-Z]+/


  def self.get_file_calibration_sum(file_path)
    return puts("File not found: #{file_path}") unless File.exist?(file_path)

    IO
      .foreach(file_path)
      .map { |line| compute_calibration(line) }
      .sum
  end

  private

  def self.compute_calibration(calibration_line)
    return 0 if calibration_line.nil? || calibration_line.empty?

    readings = collect_readings(calibration_line)
    first, last = readings.first, readings.last

    val =
      if first && last
        (first.to_i * 10) + last.to_i
      elsif last.nil?
        (first.to_i * 10) + first.to_i
      else
        0
      end
    val
  end

  def self.collect_readings(line)
    line.scan(/\d+|[a-zA-Z]+/).chunk { |value| value.match?(/\d+/) }.flat_map do |is_digit, group|
      if is_digit
        group.join.to_i
      else
        group.map { |text| convert_spelled_out_number(text) }
      end
    end.compact
  end

  def self.convert_spelled_out_number(spelled_out_number)
    NUMBER_WORDS[spelled_out_number.downcase]
  end
end

puts CalibrationDocument.get_file_calibration_sum('input/2023/day_1.txt')