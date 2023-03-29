# frozen_string_literal: true

class LocalIngester
  attr_reader :resource_class_name, :attributes, :ingest_directory
  def initialize(resource_class_name:, attributes:, ingest_directory: nil)
    @resource_class_name = resource_class_name
    @attributes = attributes
    @ingest_directory = ingest_directory
  end

  def ingest
    ingest_paths.each do |path|
      IngestFolderJob.perform_later(directory: path.to_s, file_filter: nil, class_name: resource_class_name, source_metadata_identifier: source_metadata_id_from_path(path), **attributes)
    end
  end

  # Get all paths which aren't a parent of another path.
  def ingest_paths
    path = Pathname.new(Figgy.config["ingest_folder_path"]).join(ingest_directory)
    return [] unless path.exist?
    path.children.select(&:directory?)
  end

  def source_metadata_id_from_path(path)
    base_path = File.basename(path)
    base_path if valid_remote_identifier?(base_path)
  end

  # Determines whether or not the string encodes a bib. ID or a PULFA ID
  # See SourceMetadataIdentifierValidator#validate
  # @param [String] value
  # @return [Boolean]
  def valid_remote_identifier?(value)
    RemoteRecord.valid?(value) && RemoteRecord.retrieve(value).success?
  rescue URI::InvalidURIError
    false
  end
end
