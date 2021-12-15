class MosaicGenerator
  attr_reader :resource, :storage_adapter
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
    @storage_adapter = storage_adapter
  end

  def generate; end
end
