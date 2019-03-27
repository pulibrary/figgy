# frozen_string_literal: true

# Class for an asynchronous job which retrieves the checksum for the file
class RemoteChecksumJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # Retrieve the checksum and update the resource
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

    # Retrieve the file metadata for the original file
    # @return [FileMetadata]
    def original_file
      return resource.original_file if resource.respond_to?(:original_file)
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

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def cloud_storage_file
      return if original_file.nil?

      driver.file(original_file)
    end

    # Calculate the MD5 checksum for the file locally
    # @return [String]
    def calculate_local_checksum
      return if cloud_storage_file.nil?

      temp_file = Tempfile.new(@resource_id)
      cloud_storage_file.download(temp_file.path)
      local_md5 = Digest::MD5.file(temp_file.path)
      temp_file.unlink
      local_md5.to_s
    end
end
