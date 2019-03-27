
# frozen_string_literal: true
# Class for an asynchronous job which retrieves the checksum for the file
class RemoteChecksumJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # Retrieve the checksum and update the resource
  # @param resource_id [String] the ID for the resource
  def perform(resource_id)
    @resource_id = resource_id
    remote_file = cloud_storage_file

    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      change_set = DynamicChangeSet.new(resource)

      if change_set.validate(remote_checksum: remote_file.md5)
        buffered_changeset_persister.save(change_set: change_set)
      end
    end
  end

  private

    # Construct a new ChangeSetPersister
    # @return [ChangeSetPersister]
    def change_set_persister
      @change_set_persister ||= ChangeSetPersister.new(
        metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
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

    def original_file
      resource.original_file
    end

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def cloud_storage_file
      driver.file(original_file)
    end

    # Retrieve the class used for interfacing with the remote cloud storage
    # provider
    # @return [Class]
    def cloud_storage_driver_class
      RemoteChecksumService.cloud_storage_driver_class
    end

    # Retrieve the Google Cloud Storage credentials from the configuration
    # @return [Hash]
    def credentials
      Figgy.config["google_cloud_storage"]["credentials"]
    end

    # Construct the storage driver with the necessary configuration for
    # retrieving the files
    # @return [RemoteChecksumService::GoogleCloudStorageDriver, Object]
    def driver
      return @driver unless @driver.nil?

      @driver = cloud_storage_driver_class.new(Figgy.config["google_cloud_storage"]["project_id"], credentials)
      @driver.bucket(Figgy.config["google_cloud_storage"]["bucket_name"])
      @driver
    end
end
