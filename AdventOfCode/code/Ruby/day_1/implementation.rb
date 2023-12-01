module CalibrationDocument
  TEXT_TO_NUMBER_HASH = {
    :zero => 0,
    :one => 1,
    :two => 2,
    :three => 3,
    :four => 4,
    :five => 5,
    :six => 6,
    :seven => 7,
    :eight => 8,
    :nine => 9
  }

  TEXT_TO_NUMBER_REGEX = /\b(?:#{TEXT_TO_NUMBER_HASH.keys.map { |word| Regexp.escape(word.to_s) }.join('|')})\b|\d+/

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

    first, second = scan_line_for_values(calibration_line)
    first + second
  end

  def self.scan_line_for_values(calibration_line)
    calibration_vals = calibration_line.scan(TEXT_TO_NUMBER_REGEX)

    first_digit_index = first_calibration_val(calibration_vals)
    last_digit_index = last_calibration_val(calibration_vals)

    [first_digit_index, last_digit_index]
  end

  def self.first_calibration_val(calibration_vals)

  end

  def self.last_calibration_val(calibration_vals)

  end
end

puts CalibrationDocument.get_file_calibration_sum('input/2023/day_1.txt')