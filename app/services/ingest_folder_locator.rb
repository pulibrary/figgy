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
    file_system_config = BrowseEverything.config[:file_system]
    file_system_config[:home]
  end

  # Generate the path to the studio directory used for ingestion
  # @return [Pathname]
  def root_path
    Pathname.new(upload_path_value).join("studio_new")
  end

  # Determines whether or not the directory exists
  # @return [TrueClass, FalseClass]
  def exists?
    folder_location.present?
  end

  # Retrieves the relative path from the studio ingestion directory
  # @return [Pathname]
  def location
    return unless exists?
    folder_pathname.relative_path_from(root_path)
  end

  # Counts the number of files in the directory
  # @return [Integer]
  def file_count
    return unless exists?
    Dir.glob(folder_pathname.join("**")).select do |file|
      File.file?(file)
    end.count
  end

  # Counts the number of child directories in the directory
  # @return [Integer]
  def volume_count
    return unless exists?
    Dir.glob(folder_pathname.join("**")).select do |file|
      File.directory?(file)
    end.count
  end

  # Construct or retrieve the memoized path name for the directory
  # @return [Pathname]
  def folder_pathname
    return unless exists?
    @folder_pathname ||= Pathname.new(folder_location)
  end

  private

    # Construct or retrieve the memoized file system path for the directory whose name matches the ID
    # @return [String]
    def folder_location
      @folder_location ||= Dir.glob(root_path.join("**/#{id}")).first
    end
end
