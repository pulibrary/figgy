# frozen_string_literal: true
# Class for locating folders using for file ingestion
class IngestFolderLocator
  attr_reader :id
  # Constructor
  # @param id [String] identifier for the directory
  def initialize(id:)
    @id = id
  end

  # Access the upload directory path from the BrowseEverything file system provider configuration
  # @return [String]
  def upload_path_value
    file_system_config = BrowseEverything.config["file_system"]
    file_system_config[:home]
  end

  # Generate the path to parent directory
  # @return [Pathname]
  def root_path
    Pathname.new(upload_path_value).join("studio_new")
  end

  def exists?
    folder_location.present?
  end

  def location
    return unless exists?
    folder_pathname.relative_path_from(root_path)
  end

  def file_count
    return unless exists?
    Dir.glob(folder_pathname.join("**")).select do |file|
      File.file?(file)
    end.count
  end

  def volume_count
    return unless exists?
    Dir.glob(folder_pathname.join("**")).select do |file|
      File.directory?(file)
    end.count
  end

  def folder_pathname
    @folder_pathname ||= Pathname.new(folder_location)
  end

  private

    def folder_location
      @folder_location ||= Dir.glob(root_path.join("**/#{id}")).first
    end
end
