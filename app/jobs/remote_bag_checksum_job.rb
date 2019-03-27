# frozen_string_literal: true
# Class for an asynchronous job which retrieves the checksum for the file
class RemoteBagChecksumJob < RemoteChecksumJob
  delegate :query_service, to: :metadata_adapter # Retrieve the checksum and update the resource

  # @param resource_id [String] the ID for the resource
  def perform(resource_id, local_checksum: false)
    @resource_id = resource_id
    change_set = DynamicChangeSet.new(resource)
    checksum = if local_checksum
                 calculate_local_checksum
               else
                 cloud_storage_file.md5
               end

    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      if change_set.validate(remote_checksum: checksum)
        buffered_changeset_persister.save(change_set: change_set)
      end
    end
  end

  private

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def cloud_storage_file
      driver.bag_file(compressed_bag.path.to_s, @resource_id)
    end

    def indexing_persister_adapter
      Valkyrie::MetadataAdapter.find(:indexing_persister)
    end

    # Construct a new ChangeSetPersister
    # @return [ChangeSetPersister]
    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: indexing_persister_adapter,
        storage_adapter: Valkyrie.config.storage_adapter
      )
    end

    # Retrieve the metadata adapter
    # @return [Valkyrie::MetadataAdapter]
    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end

    # Retrieve the resource
    # @return [Resource]
    def resource
      query_service.find_by(id: @resource_id)
    end

    def destination
      :bags
    end

    def bag_storage_adapter
      Valkyrie::StorageAdapter.find(destination)
    end

    def bag_exporter
      Bagit::BagExporter.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(destination),
        storage_adapter: bag_storage_adapter,
        query_service: indexing_persister_adapter.query_service
      )
    end

    def compressed_bag
      return @compressed_bag unless @compressed_bag.nil?

      bag_exporter.export(resource: resource)
      resource_bag_adapter = bag_storage_adapter.for(bag_id: resource.id)

      @compressed_bag = CompressedBag.build(path: resource_bag_adapter.storage_adapter.bag_path)
    end

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
end
