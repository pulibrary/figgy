# frozen_string_literal: true
# Class for an asynchronous job which retrieves the checksum for the file
class RemoteBagChecksumJob < RemoteChecksumJob
  delegate :query_service, to: :metadata_adapter # Retrieve the checksum and update the resource

  # @param resource_id [String] the ID for the resource
  def perform(resource_id, local_checksum: false, compressed_bag_factory: "RemoteBagChecksumService::TarCompressedBag")
    @resource_id = resource_id
    @compressed_bag_factory = compressed_bag_factory
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

    def compressed_bag_factory
      @compressed_bag_factory.constantize
    end

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

      @compressed_bag = compressed_bag_factory.build(path: resource_bag_adapter.storage_adapter.bag_path)
    end
end
