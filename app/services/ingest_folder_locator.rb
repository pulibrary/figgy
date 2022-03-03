# frozen_string_literal: true
# Class for locating folders using for file ingestion
require "find"
class IngestFolderLocator
  attr_reader :id, :search_directory
  # Constructor
  # @param id [String] identifier for the directory
  def initialize(id:, search_directory: nil)
    @id = id
    @search_directory = search_directory || default_search_directory
  end

  # Access the upload directory path from the BrowseEverything file system provider configuration
  # @return [String]
  def upload_path_value
    file_system_config = BrowseEverything.config[:fast_file_system]
    file_system_config[:home]
  end

  # Generate the path to the studio directory used for ingestion
  # @return [Pathname]
  def root_path
    Pathname.new(upload_path_value).join(search_directory)
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
    Dir.glob(folder_pathname.join("**")).count do |file|
      File.file?(file)
    end
  end

  # Counts the number of child directories in the directory
  # @return [Integer]
  def volume_count
    return unless exists?
    Dir.glob(folder_pathname.join("**")).count do |file|
      File.directory?(file)
    end
  end

  # Construct or retrieve the memoized path name for the directory
  # @return [Pathname]
  def folder_pathname
    return unless exists?
    @folder_pathname ||= Pathname.new(folder_location)
  end

  # Hash representation of locator status
  def to_h
    {
      exists: exists?,
      location: location,
      file_count: file_count,
      volume_count: volume_count
    }
  end

  private

    # Construct or retrieve the memoized file system path for the directory whose name matches the ID
    # @return [String]
    def folder_location
      @folder_location ||= Find.find(root_path).find do |path|
        FileTest.directory?(path) && path.split("/").last == id.to_s
      end
    end

    # Default sub-directory to search if not specified
    def default_search_directory
      Figgy.config["default_search_directory"]
    end
end
