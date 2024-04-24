# frozen_string_literal: true
class RetryingDiskAdapter
  attr_reader :inner_storage_adapter
  delegate :handles?, :supports?, :find_by, :delete, :upload, to: :inner_storage_adapter
  def initialize(inner_storage_adapter)
    @inner_storage_adapter = inner_storage_adapter
  end

  def upload(...)
    with_rescue([Errno::EPIPE, Errno::EAGAIN, Errno::EIO], retries: 5) do
      inner_storage_adapter.upload(...)
    end
  end

  def with_rescue(exceptions, retries: 5)
    try = 0
    begin
      yield try
    rescue *exceptions => exc
      try += 1
      try <= retries ? retry : raise(exc)
    end
  end
end
