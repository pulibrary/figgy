# frozen_string_literal: true
# Class for an asynchronous job which retrieves the checksum for the file
class RemoteBagChecksumJob < RemoteChecksumJob
  delegate :query_service, to: :metadata_adapter # Retrieve the checksum and update the resource

  # @param resource_id [String] the ID for the resource
  def perform(resource_id, local_checksum: false, compress_bag: true)
    @resource_id = resource_id
    @local_checksum = local_checksum
    @compress_bag = compress_bag

    # If bags aren't being compressed, iterate through each of the bag files in
    # the cloud and append these as a new FileSet
    if compress_bag
      if compressed_bag_file_set.nil?
        persisted_file_set = build_compressed_bag_file_set
        change_set = DynamicChangeSet.new(resource)
        if change_set.validate(member_ids: resource.member_ids + [persisted_file_set.id])
          change_set_persister.buffer_into_index do |buffered_changeset_persister|
            buffered_changeset_persister.save(change_set: change_set)
          end
        end
        resource_id = persisted_file_set.id.to_s
      else
        resource_id = compressed_bag_file_set.id.to_s
      end
    elsif bag_file_set.nil?
      persisted_file_set = build_bag_file_set
      change_set = DynamicChangeSet.new(resource)
      if change_set.validate(member_ids: resource.member_ids + [persisted_file_set.id])
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          buffered_changeset_persister.save(change_set: change_set)
        end
      end
      resource_id = persisted_file_set.id.to_s
    else
      resource_id = compressed_bag_file_set.id.to_s
    end

    RemoteChecksumJob.perform_later(resource_id, local_checksum: local_checksum)
  end

  def self.default_compressed_bag_factory
    RemoteBagChecksumService::TarCompressedBag
  end

  private

    def compressed_bag_factory
      config_option = Figgy.config["google_cloud_storage"]["bags"]["format"]
      return self.class.default_compressed_bag_factory unless config_option

      case config_option
      when "application/gzip"
        RemoteBagChecksumService::TarCompressedBag
      when "application/zip"
        RemoteBagChecksumService::ZipCompressedBag
      else
        Rails.logger.warn("Unsupported bag format provided: #{config_option}")
        self.class.default_compressed_bag_factory
      end
    end

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def compressed_cloud_storage_file
      cloud_resource = driver.file(local_file_path: compressed_bag.path.to_s, remote_file_path: @resource_id)
      RemoteChecksumService::GoogleCloudStorageFileAdapter.new(cloud_resource)
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

    def resource_bag_adapter
      return @resource_bag_adapter unless @resource_bag_adapter.nil?

      bag_exporter.export(resource: resource)
      @resource_bag_adapter = bag_storage_adapter.for(bag_id: resource.id)
    end

    def compressed_bag
      @compressed_bag ||= compressed_bag_factory.build(path: resource_bag_adapter.storage_adapter.bag_path)
    end

    # Retrieve the file entries for the contents of the bag
    # @return [Array<String>]
    def resource_bag_entries
      glob_pattern = File.join(resource_bag_adapter.storage_adapter.bag_path, "**", "*")
      Dir.glob(glob_pattern)
    end

    def resource_bag_file_entries
      resource_bag_entries.reject { |entry| File.directory?(entry) }
    end

    def relative_path(entry_path)
      segments = []
      root_segments = resource_bag_adapter.storage_adapter.bag_path.to_s.split("/")
      entry_path.to_s.split("/").each do |entry_segment|
        segments << entry_segment unless root_segments.include?(entry_segment)
      end
      File.join(*segments)
    end

    def cloud_storage_driver
      RemoteChecksumService.cloud_storage_driver
    end

    def cloud_storage_file_adapter_class
      RemoteChecksumService.cloud_storage_file_adapter_class
    end

    # Retrieve or upload the file within a Bag to a cloud service
    # return [Array<RemoteChecksumService::GoogleCloudStorageFileAdapter>]
    def cloud_storage_bag_files
      cloud_files = []
      resource_bag_file_entries.each do |entry_path|
        relative_entry_path = relative_path(entry_path)
        cloud_path = File.join(@resource_id, relative_entry_path)
        cloud_file = cloud_storage_driver.file(local_file_path: entry_path, remote_file_path: cloud_path)
        cloud_files << cloud_storage_file_adapter_class.new(cloud_file)
      end
      cloud_files
    end

    # Construct the FileMetadata objects for each file within a Bag stored the
    #   a Cloud service
    # @return [Array<FileMetadata>]
    def bag_file_metadata
      cloud_storage_bag_files.map do |cloud_storage_bag_file|
        metadata = FileMetadata.for(file: cloud_storage_bag_file).new(id: SecureRandom.uuid)

        metadata.file_identifiers << cloud_storage_bag_file.uri
        metadata
      end
    end

    # Construct a FileSet object containing the file metadata for each bag file
    # @return [FileSet]
    def build_bag_file_set
      file_set_change_set = FileSetChangeSet.new(FileSet.new)

      return unless file_set_change_set.validate(title: "Bag", file_metadata: bag_file_metadata)

      persisted_file_set = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        persisted_file_set = buffered_changeset_persister.save(change_set: file_set_change_set)
      end
      persisted_file_set
    end

    # Construct a FileMetadata object using a cloud service file resource
    # @return [FileMetadata]
    def compressed_bag_file_metadata
      metadata = FileMetadata.for(file: compressed_cloud_storage_file).new(id: SecureRandom.uuid)
      metadata.file_identifiers << compressed_cloud_storage_file.uri
      metadata
    end

    # Construct a FileSet object containing the file metadata for the compressed
    #   Bag
    # @return [FileSet]
    def build_compressed_bag_file_set
      file_set_change_set = FileSetChangeSet.new(FileSet.new)

      return unless file_set_change_set.validate(title: "Compressed Bag", file_metadata: [compressed_bag_file_metadata])

      persisted_file_set = nil
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        persisted_file_set = buffered_changeset_persister.save(change_set: file_set_change_set)
      end
      persisted_file_set
    end

    # Access the FileSet for the compressed Bag if it already exists
    # @return [FileSet]
    def compressed_bag_file_set
      resource.decorate.compressed_bag_file_set
    end

    # Access the FileSet for the Bag if it already exists
    # @return [FileSet]
    def bag_file_set
      resource.decorate.bag_file_sets.first
    end
end
