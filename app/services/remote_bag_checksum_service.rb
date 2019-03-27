# frozen_string_literal: true

# Class for calculating checksums for resources managed in cloud storage
class RemoteBagChecksumService
  # Model for compressing bag directories into ZIP-compressed files
  class CompressedBag
    attr_reader :path

    # Construct an object using a path to the directory
    # @param path [String] path to the directory containing the bag files
    # @return [CompressedBag]
    def self.build(path:)
      zip_file_path = path.to_s.chomp("/") + ".zip"
      new(bag_path: path, zip_path: zip_file_path)
    end

    # Constructor
    # @param bag_path [String] path to the directory containing the bag files
    # @param zip_path [String] path to the ZIP file
    def initialize(bag_path:, zip_path:)
      raise StandardError, "Only directories can be compressed into ZIP files" unless File.directory?(bag_path)

      @bag_path = bag_path
      Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
        @zip_file = zip_file
        compress_entries(bag_path, root_entries)
      end
      @path = Pathname.new(zip_path)
    end

    private

      # Generate the file system entry paths for the bag directory
      # @return [Array<String>]
      def root_entries
        Dir.glob(File.join(@bag_path, "*"))
      end

      # Compress a directory into the ZIP file
      # @param directory_path [String]
      def compress_directory(directory_path)
        directory_name = File.basename(directory_path)

        # This needs to be handled unless Errno::EEXIST is raised
        @zip_file.mkdir directory_name unless @zip_file.find_entry(directory_name)

        directory_entries = Dir.glob(File.join(directory_path, "*"))

        compress_entries(directory_path, directory_entries)
      end

      # Compress a file into the ZIP archive
      # @param file_path [String]
      def compress_file(file_path)
        zip_entry_name = File.basename(file_path)

        @zip_file.get_output_stream(zip_entry_name) do |f|
          bitstream = File.open(file_path, "rb").read
          f.write(bitstream)
        end
      end

      # Compress a file system entry into the ZIP archive
      # @param parent_path [String] path to the parent directory for the entries
      # @param entry_path [String] the file system entry path
      def compress_entry(parent_path, entry_path)
        entry_name = File.basename(entry_path)
        return if /^\.\.?$/ =~ entry_name

        full_entry_path = File.join(parent_path, entry_name)

        if File.directory? full_entry_path
          compress_directory(full_entry_path)
        else
          compress_file(full_entry_path)
        end
      end

      # Compress a set of file system entries into the ZIP archive
      # @param parent_path [String] path to the parent directory for the entries
      # @param entry_path [Array<String>] the file system entry paths
      def compress_entries(parent_path, entries)
        entries.map { |entry| compress_entry(parent_path, entry) }
      end
  end

  # Provide the default class for interfacing with cloud storage provider
  # @return [Class]
  def self.cloud_storage_driver_class
    RemoteChecksumService::GoogleCloudStorageDriver
  end

  # Retrieve the class used for asynchronous job
  # @return [Class]
  def self.remote_checksum_job_class
    RemoteBagChecksumJob
  end

  # Constructor
  # @param change_set [Valkyrie::ChangeSet] ChangeSet for the resource being
  #   modified
  def initialize(change_set)
    @change_set = change_set
  end

  # Calculate the checksum for the resource in the cloud and persist it for the
  # resource
  def calculate
    return if @change_set.resource.id.nil?

    self.class.remote_bag_checksum_job.perform_later(id: @change_set.resource.id)
  end
end
