
# frozen_string_literal: true
# Class for an asynchronous job which retrieves the checksum for the file
class RemoteChecksumJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # Retrieve the checksum and update the resource
  # @param resource_id [String] the ID for the resource
  def perform(resource_id)
    @resource_id = resource_id

    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      file = cloud_storage_file
      change_set.populate! # I'm not supposed to do this?
      change_set.remote_checksum = file.md5

      buffered_changeset_persister.persist(change_set: change_set)
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

    # Construct a ChangeSet for the resource
    # @return [ChangeSet]
    def change_set
      DynamicChangeSet.new(resource)
    end

    # Generate the file name from the resource ID
    # @return [String]
    def file_name
      resource.id.to_s
    end

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def cloud_storage_file
      driver.file(file_name)
    end

    # Retrieve the class used for interfacing with the remote cloud storage
    # provider
    # @return [Class]
    def cloud_storage_driver_class
      RemoteChecksumService.cloud_storage_driver_class
    end

    # Construct the storage driver with the necessary configuration for
    # retrieving the files
    # @return [RemoteChecksumService::GoogleCloudStorageDriver, Object]
    def driver
      return @driver unless @driver.nil?

      @driver = cloud_storage_driver_class.new(Figgy.config["google_cloud_storage"]["project_id"])
      @driver.bucket(Figgy.config["google_cloud_storage"]["bucket_name"])
      @driver
    end
end
