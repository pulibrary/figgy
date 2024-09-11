# frozen_string_literal: true
class FileWatcherStatus < HealthMonitor::Providers::Base
  class FileWatcherStatusCheckError < StandardError; end

  def check!
    ocr_in_path = Figgy.config["ocr_in_path"]
    files = Dir["#{ocr_in_path}/*"].select { |f| File.file? f }
    old_files = files.find_all do |f|
      too_old?(f) && valid_filename?(f)
    end
    raise FileWatcherStatusCheckError if old_files.count.positive?
  end

  def too_old?(file)
    File.mtime(file) < twelve_hours_ago
  end

  def valid_filename?(file)
    /^\d+$/ =~ File.basename(file, ".pdf")
  end

  def twelve_hours_ago
    @twelve_hours_ago ||= Time.current.to_time - 12.hours
  end
end
