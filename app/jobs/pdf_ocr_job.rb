# frozen_string_literal: true
class PdfOcrJob < ApplicationJob
  class_attribute :max_wait, :sleep_interval

  # Max time in seconds to wait for the file to be released by another process.
  # Needed when copying large files to the input directory or
  # transferring over the network.
  self.max_wait = 300

  # Time in seconds to wait between open file checks
  self.sleep_interval = 10

  def perform(in_path:, out_path:)
    wait_for_file(in_path)
    _stdout_str, error_str, status = Open3.capture3("ocrmypdf", "--force-ocr", "--rotate-pages", "--deskew", in_path.to_s, out_path.to_s)
    raise "PDF OCR job failed: #{error_str}" unless status.success?
    File.delete(in_path)
  end

  def wait_for_file(in_path)
    counter = 0
    loop do
      raise "PDF OCR job failed: Timed out. File is open by another process." if counter >= max_wait
      stdout_str, error_str, _status = Open3.capture3("lsof", in_path.to_s)
      break if stdout_str == "" && error_str == ""
      raise "PDF OCR job failed: #{error_str}" if error_str != ""
      counter += sleep_interval
      sleep sleep_interval
    end
  end
end
