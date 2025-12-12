# frozen_string_literal: true
class RetryingDiskAdapter
  attr_reader :inner_storage_adapter
  delegate :handles?, :supports?, :find_by, :delete, :upload, :base_path, :file_path, :file_mover, :protocol, to: :inner_storage_adapter
  def initialize(inner_storage_adapter)
    @inner_storage_adapter = inner_storage_adapter
  end

  def upload(**args)
    FiggyUtils.with_rescue([Errno::EPIPE, Errno::EAGAIN, Errno::EIO, Errno::ECONNRESET], retries: 5) do
      inner_storage_adapter.upload(**args)
    end
  end
end
