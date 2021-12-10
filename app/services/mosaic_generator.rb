# frozen_string_literal: true
class MosaicGenerator
  class Error < StandardError; end

  attr_reader :resource, :storage_adapter
  # @param resource [RasterResource]
  def initialize(resource:, storage_adapter:)
    @resource = resource.decorate
    @storage_adapter = storage_adapter
  end

  # @return [FileMetadata] the FileMetadata Object node linked to the mosaic
  def render
    return unless resource.raster_set?
    return unless generate_mosaic
    build_node
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

  def mosaic_command
    "echo \"#{raster_paths}\" | #{access_key} #{secret_access_key} LC_ALL=C.UTF-8 LANG=C.UTF-8 cogeo-mosaic create - -o #{tmp_file.path}"
  end

  def access_key
    "AWS_ACCESS_KEY_ID=#{Figgy.config['aws_access_key_id']}"
  end

  def secret_access_key
    "AWS_SECRET_ACCESS_KEY=#{Figgy.config['aws_secret_access_key']}"
  end

  def build_node
    file = IngestableFile.new(file_path: tmp_file.path, mime_type: "application/json", original_filename: "mosaic.json")
    node = FileMetadata.for(file: file).new(id: SecureRandom.uuid)
    stored_file = storage_adapter.upload(resource: node, file: file, original_filename: Array.wrap(node.original_filename).first)
    node.file_identifiers = stored_file.id
    node
  end

  def tmp_file
    @tmp_file ||= Tempfile.new("mosaic")
  end
end
