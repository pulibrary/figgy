# frozen_string_literal: true

class MosaicGenerator
  attr_reader :resource, :storage_adapter
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
  end

  def generate
    path = Valkyrie::Storage::Disk::BucketedStorage.new(base_path: "s3://figgy-geo-staging").generate(resource: resource, original_filename: "mosaic.json", file: nil).to_s
  end
end
