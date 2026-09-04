# frozen_string_literal: true

require "rails_helper"

RSpec.describe "bin/pdf_watcher" do
  let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }

  after do
    stop_watcher
  end

  it "enqueues a job for numeric PDF filenames" do
    Dir.mktmpdir do |dir|
      log_file = File.open(Pathname.new(dir).join("test_log.log"), "w+")
      start_watcher(log_file)

      FileUtils.cp(fixture_path, File.join(dir, "12345.pdf"))
      Timeout.timeout(10) do
        sleep(0.25) until log_file.gets.to_s.match?(/Enqueued CreateOcrRequestJob for: .*12345\.pdf/)
      end
    end
  end

  # Launch the bin file in a sub-process and track its pid/log, we'll kill it
  # later.
  def start_watcher(log_file)
    @watcher_pid = Process.spawn(
      { "RAILS_ENV" => "test", "PDF_WATCHER_FILE_WAIT_TIME" => "1", "OCR_ILLIAD_IN_PATH" => File.dirname(log_file.path) },
      Rails.root.join("bin", "pdf_watcher").to_s,
      out: log_file.path
    )
    # Wait until it boots up.
    Timeout.timeout(10) do
      sleep(0.25) until log_file.gets.to_s.include?("PdfWatcher watching")
    end
  end

  def stop_watcher
    Process.kill("TERM", @watcher_pid)
    Process.waitpid(@watcher_pid)
  end
end
