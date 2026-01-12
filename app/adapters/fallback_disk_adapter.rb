# frozen_string_literal: true
class FallbackDiskAdapter
  attr_reader :primary_adapter, :fallback_adapter
  delegate :handles?, :supports?, :find_by, :delete, :upload, :base_path, :file_path, :protocol, :file_mover, to: :primary_adapter
  def initialize(primary_adapter:, fallback_adapter:)
    @primary_adapter = primary_adapter
    @fallback_adapter = fallback_adapter
  end

  def find_by(id:)
    # Check to see if the file's readable, fallback if not.
    # If Tigerdata doesn't have a solid connection to the Isilon, this will
    # fail. If it takes a long time, Tigerdata's frozen up, fail generally and
    # don't fallback.
    Timeout.timeout(2) do
      resource = primary_adapter.find_by(id: id)
      File.open(resource.disk_path, "rb") do |file|
        # Read just one byte.
        file.read(1)
      end
      resource
    end
  rescue Valkyrie::StorageAdapter::FileNotFound, Errno::EIO
    # This'll only work for disk adapters, but that's our use case.
    new_id = id.to_s.gsub(primary_adapter.base_path.to_s, fallback_adapter.base_path.to_s)
    file = fallback_adapter.find_by(id: new_id)
    Rails.logger.warn("Disk adapter used fallback for #{id}")
    file.new(id: id)
  end
end
