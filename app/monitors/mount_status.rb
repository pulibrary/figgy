# frozen_string_literal: true

class MountStatus < HealthMonitor::Providers::Base
  def check!
    system_mounts = Sys::Filesystem.mounts.map(&:mount_point)
    expected_mounts.map do |emount|
      next if system_mounts.include?(emount)
      raise "#{emount} was expected to be mounted but is not"
    end
  end

  def expected_mounts
    [
      "/mnt/diglibdata/pudl",
      "/mnt/diglibdata/hydra_binaries",
      "/mnt/hydra_sources/ingest_scratch",
      "/mnt/hydra_sources/pudl",
      "/mnt/hydra_sources/archives",
      "/mnt/hydra_sources/archives_bd",
      "/mnt/hydra_sources/maplab",
      "/mnt/hydra_sources/bitcur-archives",
      "/mnt/hydra_sources/studio_new",
      "/mnt/hydra_sources/marquand",
      "/mnt/hydra_sources/mendel",
      "/mnt/hydra_sources/mudd",
      "/mnt/hydra_sources/microforms",
      "/mnt/hydra_sources/music",
      "/mnt/hydra_sources/numismatics",
      "/mnt/illiad/images",
      "/mnt/illiad/ocr_scan",
      "/mnt/illiad/cdl_scans",
      "/mnt/hosted_illiad/ILL_OCR_Scans"
    ]
  end
end
