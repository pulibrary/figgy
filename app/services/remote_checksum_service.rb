# frozen_string_literal: true
require "google/cloud/storage"

# Class for calculating checksums for resources managed in cloud storage
class RemoteChecksumService
  # Class providing an interface for the FileAppender service for appending
  # Google Cloud files
  class GoogleCloudStorageFileAdapter
    def self.bag_uri
      RDF::URI("http://figgy.princeton.edu/vocab#Bag")
    end

    # Constructor
    def initialize(file)
      @file = file
    end

    def original_filename
      @file.name
    end

    def content_type
      @file.content_type
    end

    def use
      [self.class.bag_uri]
    end

    def cloud_file?
      true
    end

    def id
      Valkyrie::ID.new(@file.gapi.self_link)
    end
  end

  # Base class for interfacing with cloud storage service APIs
  class CloudServiceDriver; end

  # Class for interfacing with the Google Cloud Storage API
  class GoogleCloudStorageDriver < CloudServiceDriver
    # Constructor
    # @param project_id [String] the ID for the Google Project
    # @param credentials [Hash] the credentials for the Google Cloud Storage API
    def initialize(project_id, credentials)
      @storage = Google::Cloud::Storage.new(project_id: project_id, credentials: credentials)
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

      retrieved = @current_bucket.file(file.id.to_s)
      return retrieved unless retrieved.nil?

      file_node = Valkyrie.config.storage_adapter.find_by(id: file.file_identifiers.first)
      @current_bucket.create_file(file_node.disk_path.to_s, file.id.to_s)
    end

    def bag_file(local_file_path, remote_file_path)
      raise StandardError, "A bucket needs to be selected before a file can be downloaded." if @current_bucket.nil?

      retrieved = @current_bucket.file(remote_file_path)
      return retrieved unless retrieved.nil?

      @current_bucket.create_file(local_file_path, remote_file_path)
    end
  end

  # Provide the default class for interfacing with cloud storage provider
  # @return [Class]
  def self.cloud_storage_driver_class
    GoogleCloudStorageDriver
  end

  # Retrieve the class used for asynchronous job
  # @return [Class]
  def self.remote_checksum_job_class
    RemoteChecksumJob
  end

  def self.cloud_storage_file_adapter_class
    GoogleCloudStorageFileAdapter
  end

  # Retrieve the Google Cloud Storage credentials from the configuration
  # @return [Hash]
  def self.cloud_storage_credentials
    Figgy.config["google_cloud_storage"]["credentials"]
  end

  def self.cloud_storage_project_id
    Figgy.config["google_cloud_storage"]["project_id"]
  end

  def self.cloud_storage_bucket
    Figgy.config["google_cloud_storage"]["bucket_name"]
  end

  # Construct the storage driver with the necessary configuration for
  # retrieving the files
  # @return [RemoteChecksumService::GoogleCloudStorageDriver, Object]
  def self.cloud_storage_driver
    return @driver unless @driver.nil?

    @driver = cloud_storage_driver_class.new(cloud_storage_project_id, cloud_storage_credentials)
    @driver.bucket(cloud_storage_bucket)
    @driver
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

    self.class.remote_checksum_job.perform_later(id: @change_set.resource.id)
  end
end
