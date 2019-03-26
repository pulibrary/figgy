# frozen_string_literal: true
require "google/cloud/storage"

# Class for calculating checksums for resources managed in cloud storage
class RemoteChecksumService
  # Base class for interfacing with cloud storage service APIs
  class CloudServiceDriver; end

  # Class for interfacing with the Google Cloud Storage API
  class GoogleCloudStorageDriver < CloudServiceDriver
    # Constructor
    # @param project_id [String] the ID for the Google Project
    def initialize(project_id)
      @storage = Google::Cloud::Storage.new(project_id: project_id)
      @buckets = {}
      @current_bucket = nil
    end

    # Retrieve a bucket by its name
    # @param name [String] the name for the bucket
    # @return [Google::Cloud::Storage::Bucket]
    def bucket(name)
      return @buckets[name] if @buckets.key?(name)

      retrieved = @storage.bucket(name)
      retrieved = @storage.create_bucket(name) if retrieved.nil?
      @buckets[name] = retrieved
      @current_bucket = @buckets[name]
    end

    # Retrieve a cloud storage file resource from the API
    # @param file [FileMetadata] 
    # @return [Google::Cloud::Storage::File]
    def file(file)
      raise StandardError, "A bucket needs to be selected before a file can be downloaded." if @current_bucket.nil?

      retrieved = @current_bucket.file(file.file_identifiers.first.to_s)

      if retrieved.nil?
        file_node = Valkyrie.config.storage_adapter.find_by(id: file.file_identifiers.first)
        retrieved = @current_bucket.create_file(file_node.disk_path.to_s, file.id.to_s)
      end
    end
  end

  # Provide the default class for interfacing with cloud storage provider
  # @return [Class]
  def self.cloud_storage_driver_class
    GoogleCloudStorageDriver
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

    remote_checksum_job.perform_later(id: @change_set.resource.id)
  end

  private

    # Retrieve the class used for asynchronous job
    # @return [Class]
    def remote_checksum_job_class
      RemoteChecksumJob
    end
end
