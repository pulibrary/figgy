# frozen_string_literal: true
class RetryingDiskAdapter
  attr_reader :inner_storage_adapter
  delegate :handles?, :supports?, :find_by, :delete, :upload, to: :inner_storage_adapter
  def initialize(inner_storage_adapter)
    @inner_storage_adapter = inner_storage_adapter
  end

  def upload(...)
    FiggyUtils.with_rescue([Errno::EPIPE, Errno::EAGAIN, Errno::EIO, Errno::ECONNRESET], retries: 5) do
      inner_storage_adapter.upload(...)
    end
  end
end
