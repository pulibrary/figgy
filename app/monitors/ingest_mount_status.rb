# frozen_string_literal: true
class IngestMountStatus < HealthMonitor::Providers::Base
  def check!
    ingest_mount = Figgy.config["ingest_folder_path"]
    contents = Dir.glob(ingest_mount)
    raise "ingest mount #{ingest_mount} is empty" if contents.empty?
  end
end
