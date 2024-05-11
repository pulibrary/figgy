# frozen_string_literal: true

# This class provides uris for mosaic manifests and cloud rasters.
# It calls out to the MosaicGenerator as needed.
class TileMetadataService
  class Error < StandardError; end
  attr_reader :resource, :generate
  # @param resource [RasterResource, ScannedMap]
  def initialize(resource:, generate: false)
    @resource = resource.decorate
    @generate = generate
  end

  def full_path
    raise Error if raster_file_sets.empty?
    if mosaic?
      # Path to mosaic.json file
      mosaic_path
    else
      # Path to cloud raster file
      raster_paths.first
    end
  end

  def path
    full_path.gsub(base_path, "")
  end

  def mosaic?
    # A mosaic is single service comprised of multiple raster datasets.
    # This tests if there are multiple child raster FileSets.
    return true if raster_file_sets.count > 1
    false
  end

  def mosaic_path
    # build default mosaic file
    if @generate
      raise Error unless MosaicGenerator.new(output_path: tmp_file.path, raster_paths: raster_paths).run
    end

    build_node(default_filename)
    Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: default_filename, file: nil).to_s
  end

  # Refactor once https://github.com/samvera/valkyrie/issues/887 is resolved
  #   and make private if possible
  def base_path
    if cloud_storage_adapter?
      "s3://#{storage_adapter.shrine.bucket.name}"
    else
      storage_adapter.base_path.to_s
    end
  end

  def mosaic_file_id
    if cloud_storage_adapter?
      "#{storage_adapter.send(:protocol_with_prefix)}#{storage_adapter.path_generator.generate(resource: resource, original_filename: default_filename, file: nil)}"
    else
      "disk://#{storage_adapter.path_generator.generate(resource: resource, original_filename: default_filename, file: nil)}"
    end
  end

  private

    def build_node(file_name)
      file = IngestableFile.new(file_path: tmp_file.path, mime_type: "application/json", original_filename: file_name, use: [::PcdmUse::CloudDerivative])
      # the storage adapter will use this id as the storage location
      node = FileMetadata.for(file: file).new(id: resource.id)
      storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first) unless File.zero?(tmp_file.path)
      tmp_file.close
    end

    def default_filename
      "mosaic.json"
    end

    def cloud_storage_adapter?
      storage_adapter.is_a? Valkyrie::Storage::Shrine
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
