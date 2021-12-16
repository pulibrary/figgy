# frozen_string_literal: true

class MosaicGenerator
  attr_reader :resource
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
  end

  def path
    Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: "mosaic.json", file: nil).to_s
  end

  private

    def base_path
      if storage_adapter.is_a? Valkyrie::Storage::Shrine
        "s3://#{storage_adapter.shrine.bucket.name}"
      else
        storage_adapter.storage_adapter.base_path.to_s
      end
    end

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
    end
end
