# frozen_string_literal: true

# This class provides uris for mosaic manifests and cloud rasters.
# It calls out to the MosaicGenerator as needed.
class TileMetadataService
  class Error < StandardError; end
  attr_reader :resource
  # @param resource [RasterResource, ScannedMap]
  def initialize(resource:)
    @resource = resource.decorate
  end

  def path
    if mosaic?
      # Path to mosaic.json file
      mosaic_path
    else
      # Path to cloud raster file
      raster_paths.first
    end
  end

  def mosaic?
    return true if resource.is_a?(RasterResource) && resource.decorate.raster_resources_count.positive?
    return true if raster_file_sets.count > 1
    false
  end

  def mosaic_path
    raise Error if raster_file_sets.empty?
    document_path = Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: fingerprinted_filename, file: nil).to_s
    return document_path if storage_adapter.find_by(id: mosaic_file_id)
  rescue Valkyrie::StorageAdapter::FileNotFound
    raise Error unless MosaicGenerator.new(output_path: tmp_file.path, raster_paths: raster_paths).run

    # build default mosaic file
    build_node(default_filename)

    # save copy of mosaic file with fingerprinted file name
    build_node(fingerprinted_filename)
    document_path
  end

  # Refactor once https://github.com/samvera/valkyrie/issues/887 is resolved
  #   and make private if possible
  def base_path
    if storage_adapter.is_a? Valkyrie::Storage::Shrine
      "s3://#{storage_adapter.shrine.bucket.name}"
    else
      storage_adapter.base_path.to_s
    end
  end

  # Refactor once https://github.com/samvera/valkyrie/issues/887 is resolved
  #   and make private if possible
  def mosaic_file_id
    if storage_adapter.is_a? Valkyrie::Storage::Shrine
      "#{storage_adapter.send(:protocol_with_prefix)}#{storage_adapter.path_generator.generate(resource: resource, original_filename: fingerprinted_filename, file: nil)}"
    else
      "disk://#{storage_adapter.path_generator.generate(resource: resource, original_filename: fingerprinted_filename, file: nil)}"
    end
  end

  private

    def build_node(file_name)
      file = IngestableFile.new(file_path: tmp_file.path, mime_type: "application/json", original_filename: file_name, use: [Valkyrie::Vocab::PCDMUse.CloudDerivative])
      # the storage adapter will use this id as the storage location
      node = FileMetadata.for(file: file).new(id: resource.id)
      storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first) unless File.zero?(tmp_file.path)
      tmp_file.close
    end

    def default_filename
      "mosaic.json"
    end

    def fingerprint
      @fingerprint ||= query_service.custom_queries.mosaic_fingerprint_for(id: resource.id)
    end

    def fingerprinted_filename
      "mosaic-#{fingerprint}.json"
    end

    def query_service
      ChangeSetPersister.default.query_service
    end

    def raster_file_sets
      @raster_file_sets ||= query_service.custom_queries.mosaic_file_sets_for(id: resource.id)
    end

    def raster_paths
      raster_file_sets.map do |fs|
        fs.file_metadata.map(&:cloud_uri)
      end.flatten.compact
    end

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
    end

    def tmp_file
      @tmp_file ||= Tempfile.new("mosaic")
    end
end
