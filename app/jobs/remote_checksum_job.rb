# frozen_string_literal: true

# Class for an asynchronous job which retrieves the checksum for the file
class RemoteChecksumJob < ApplicationJob
  delegate :query_service, to: :metadata_adapter

  # Retrieve the checksum and update the resource
  # @param resource_id [String] the ID for the resource
  def perform(resource_id, local_checksum: false)
    @resource_id = resource_id

    cloud_file_metadata.each do |cloud_file_metadata|
      cloud_storage_file = driver.file(file_metadata: cloud_file_metadata)

      checksum = if local_checksum
                   calculate_local_checksum(file: cloud_storage_file)
                 else
                   cloud_storage_file.md5
                 end
      cloud_storage_file.checksum = checksum
    end

    change_set = DynamicChangeSet.new(resource)
    change_set_persister.buffer_into_index do |buffered_changeset_persister|
      if change_set.validate(file_metadata: file_metadata)
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

    # Construct the storage driver with the necessary configuration for
    # retrieving the files
    # @return [RemoteChecksumService::GoogleCloudStorageDriver, Object]
    def driver
      return @driver unless @driver.nil?
      @driver = RemoteChecksumService.cloud_storage_driver
    end

    # Calculate the MD5 checksum for the file locally
    # @return [String]
    def calculate_local_checksum(file:)
      return if file.nil?

      temp_file = Tempfile.new
      file.download(temp_file.path)
      local_md5 = Digest::MD5.file(temp_file.path)
      temp_file.unlink
      local_md5.base64digest
    end

    def file_metadata
      @file_metadata ||= resource.file_metadata
    end

    def cloud_file_metadata
      file_metadata.select { |file_metadata| file_metadata.use.include?(RemoteChecksumService::GoogleCloudStorageFileAdapter.bag_uri) }
    end
end
