# frozen_string_literal: true

class MosaicService
  class Error < StandardError; end
  attr_reader :resource
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
  end

  # def fingerprinted_path
  # end

  # calculate the path for the non-fingerprinted version of the file
  def path
    raise Error if raster_file_sets.empty?
    mosaic_path = Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: "mosaic.json", file: nil).to_s
    return mosaic_path if storage_adapter.find_by(id: mosaic_file_id)
  rescue Valkyrie::StorageAdapter::FileNotFound
    build_node if MosaicGenerator.new(output_path: tmp_file.path, raster_paths: raster_paths).run
    mosaic_path
  end

  # This should be private, but we have to test the S3 code path
  def base_path
    if storage_adapter.is_a? Valkyrie::Storage::Shrine
      "s3://#{storage_adapter.shrine.bucket.name}"
    else
      storage_adapter.storage_adapter.base_path.to_s
    end
  end

  def mosaic_file_id
    if storage_adapter.is_a? Valkyrie::Storage::Shrine
      "#{storage_adapter.send(:protocol_with_prefix)}#{storage_adapter.path_generator.generate(resource: resource, original_filename: 'mosaic.json', file: nil)}"
    else
      "disk://#{storage_adapter.path_generator.generate(resource: resource, original_filename: 'mosaic.json', file: nil)}"
    end
  end

  private

    def storage_adapter
      @storage_adapter ||= Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
    end

    def build_node
      file = IngestableFile.new(file_path: tmp_file.path, mime_type: "application/json", original_filename: "mosaic.json", use: [Valkyrie::Vocab::PCDMUse.CloudDerivative])
      # the storage adapter will use this id as the storage location
      node = FileMetadata.for(file: file).new(id: resource.id)
      storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first) unless File.zero?(tmp_file.path)
    end

    def tmp_file
      @tmp_file ||= Tempfile.new("mosaic")
    end

    def raster_paths
      raster_file_sets.map do |fs|
        fs.file_metadata.map(&:cloud_url)
      end.flatten.compact.join("\n")
    end

    def raster_file_sets
      @raster_file_sets ||= resource.decorated_raster_resources.map { |r| r.decorate.geo_members }.flatten
    end
end