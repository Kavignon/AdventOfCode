module CalibrationDocument
  def self.get_calibration_value(file_path)
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
    digits_in_line = calibration_line.chars.select { |c| c.match?(/\d/) }
    [digits_in_line.first.to_i * 10, digits_in_line.last.to_i]
  end
end

CalibrationDocument.get_calibration_value('input/2023/day_1.txt')