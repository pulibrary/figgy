# frozen_string_literal: true

class MosaicGenerator
  attr_reader :resource
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
  end

  # def fingerprinted_path
  # end

  # calculate the path for the non-fingerprinted version of the file
  def path
    # check whether it exists
    generate_mosaic
    build_node
    Valkyrie::Storage::Disk::BucketedStorage.new(base_path: base_path).generate(resource: resource, original_filename: "mosaic.json", file: nil).to_s
  end

  # This should be private, but we have to test the S3 code path
  def base_path
    if storage_adapter.is_a? Valkyrie::Storage::Shrine
      "s3://#{storage_adapter.shrine.bucket.name}"
    else
      storage_adapter.storage_adapter.base_path.to_s
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
      storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first)
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
      resource.decorated_raster_resources.map { |r| r.decorate.geo_members }.flatten
    end

    def generate_mosaic
      _stdout_str, error_str, status = Open3.capture3(mosaic_command)
      raise StandardError, error_str unless status.success?
      true
    end

    # need the key to read the images
    def mosaic_command
      "echo \"#{raster_paths}\" | #{access_key} #{secret_access_key} LC_ALL=C.UTF-8 LANG=C.UTF-8 cogeo-mosaic create - -o #{tmp_file.path}"
    end

    def access_key
      "AWS_ACCESS_KEY_ID=#{Figgy.config['aws_access_key_id']}"
    end

    def secret_access_key
      "AWS_SECRET_ACCESS_KEY=#{Figgy.config['aws_secret_access_key']}"
    end
end
