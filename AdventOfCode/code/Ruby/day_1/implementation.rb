module CalibrationDocument
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
    calibration_readings = calibration_line.chars.select { |c| c.match?(/\d/) }

    [first_calibration_reading(calibration_readings), last_calibration_reading(calibration_readings)]
  end

    def self.first_calibration_reading(calibration_vals)
      calibration_vals.first.to_i * 10
    end

    def self.last_calibration_reading(calibration_vals)
      calibration_vals.last.to_i
    end
end

puts CalibrationDocument.get_file_calibration_sum('input/2023/day_1.txt')