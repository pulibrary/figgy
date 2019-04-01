# frozen_string_literal: true

# Class for an asynchronous job which retrieves the checksum for the file
class RemoteFileSetChecksumJob < RemoteChecksumJob
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

    # Retrieve the file metadata for the original file
    # @return [FileMetadata]
    def original_file
      return resource.original_file if resource.respond_to?(:original_file)
    end

    # Retrieve the file resource from cloud storage
    # @return [Google::Cloud::Storage::File, Object]
    def cloud_storage_file
      return if original_file.nil?

      driver.file(file_metadata: original_file)
    end

    # Calculate the MD5 checksum for the file locally
    # @return [String]
    def calculate_local_checksum
      return if cloud_storage_file.nil?

      temp_file = Tempfile.new(@resource_id)
      cloud_storage_file.download(temp_file.path)
      local_md5 = Digest::MD5.file(temp_file.path)
      temp_file.unlink
      local_md5.base64digest
    end
end
