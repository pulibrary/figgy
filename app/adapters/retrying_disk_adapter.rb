class RetryingDiskAdapter
  class InvalidPath < StandardError; end

  attr_reader :inner_storage_adapter
  delegate :handles?, :supports?, :find_by, :delete, :upload, :base_path, :file_path, :file_mover, :protocol, to: :inner_storage_adapter
  def initialize(inner_storage_adapter)
    @inner_storage_adapter = inner_storage_adapter
  end

  def upload(**args)
    validate_destination!(**args)
    FiggyUtils.with_rescue([Errno::EPIPE, Errno::EAGAIN, Errno::EIO, Errno::ECONNRESET], retries: 5) do
      inner_storage_adapter.upload(**args)
    end
  end

  private

    # Don't allow uploads outside of the base_path.
    # TODO: Fix this in Valkyrie.
    def validate_destination!(file:, original_filename:, resource: nil, **_args)
      path_generator = inner_storage_adapter.try(:path_generator)
      return unless path_generator
      destination = File.expand_path(path_generator.generate(resource: resource, file: file, original_filename: original_filename))
      return if destination.start_with?("#{File.expand_path(base_path)}/")
      raise InvalidPath, "#{original_filename} would be stored outside of #{base_path}"
    end
end
