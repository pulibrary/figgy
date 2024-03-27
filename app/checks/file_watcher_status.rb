# frozen_string_literal: true
class FileWatcherStatus < HealthMonitor::Providers::Base
  class FileWatcherStatusCheckError < StandardError; end

  def check!
    ocr_in_path = Figgy.config["ocr_in_path"]
    files = Dir["#{ocr_in_path}/*"].select { |f| File.file? f }
    twelve_hours_ago = Time.current.to_time - 12.hours
    old_files = files.find_all do |f|
      File.mtime(f) < twelve_hours_ago
    end
    raise FileWatcherStatusCheckError if old_files.count.positive?
  end
end
