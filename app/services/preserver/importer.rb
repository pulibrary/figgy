# frozen_string_literal: true

class Preserver
  class Importer
    attr_reader :metadata_file_identifier, :binary_file_identifiers, :storage_adapter, :change_set_persister

    def self.default_storage_adapter
      Valkyrie::StorageAdapter.find(:versioned_google_cloud_storage)
    end

    # @param resource [PreservationObject]
    def self.from_preservation_object(resource:, change_set_persister:, storage_adapter: nil)
      file_metadata = resource.metadata_node
      metadata_file_identifier = file_metadata&.file_identifiers&.first
      binary_file_identifiers = resource.binary_nodes.map(&:file_identifiers).flatten
      resource_storage_adapter = storage_adapter || default_storage_adapter

      new(
        metadata_file_identifier: metadata_file_identifier,
        binary_file_identifiers: binary_file_identifiers,
        change_set_persister: change_set_persister,
        storage_adapter: resource_storage_adapter
      ).import!
    end

    def initialize(metadata_file_identifier:, binary_file_identifiers:, change_set_persister:, storage_adapter: nil)
      @metadata_file_identifier = metadata_file_identifier
      @binary_file_identifiers = binary_file_identifiers
      @storage_adapter = storage_adapter || default_storage_adapter
      @change_set_persister = change_set_persister
    end

    def import!
      files = import_binary_nodes(binary_file_identifiers)
      fs_change_set = ChangeSet.for(file_set)

      # Delete historic metadata because we are about to add new ones for the restored file(s)
      fs_change_set.validate(files: files, file_metadata: [])

      imported = nil
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        imported = buffered_change_set_persister.save(change_set: fs_change_set, external_resource: true)
      end

      imported
    end

    private

      def file_set
        @file_set ||= begin
                        Valkyrie.config.metadata_adapter.resource_factory.to_resource(object: resource_object)
                      rescue Valkyrie::StorageAdapter::FileNotFound
                        FileSet.new
                      end
      end

      def resource_object
        metadata_file_contents = storage_adapter.find_by(id: metadata_file_identifier).read
        metadata_json = JSON.parse(metadata_file_contents)
        # Set the lock version so the Valkyrie ORM Converter can generate a lock token
        lock_version = metadata_json.dig("optimistic_lock_token", 0, "token")

        { metadata: metadata_json, lock_version: lock_version }
      end

      def import_binary_nodes(file_identifiers)
        files = file_identifiers.map { |file_id| import_binary_node(file_id) }
        files.compact
      end

      def import_binary_node(file_identifier)
        stored_file = storage_adapter.find_by(id: file_identifier)
        IngestableFile.new(
          file_path: stored_file.disk_path,
          mime_type: "application/octet-stream",
          original_filename: filename_from_metadata(file_identifier) || File.basename(stored_file.disk_path),
          use: use_from_metadata(file_identifier)
        )
      rescue Valkyrie::StorageAdapter::FileNotFound => not_found_error
        Rails.logger.error("#{file_identifier} could not be retrieved: #{not_found_error.message}")
        nil
      end

      # Get file PCDM use value from imported file metadata
      def use_from_metadata(file_identifier)
        file_metadata = file_set.file_metadata.find { |fm| file_identifier.id.include? fm.id.id }
        if file_metadata
          file_metadata.use
        else
          ::PcdmUse::OriginalFile
        end
      end

      def filename_from_metadata(file_identifier)
        file_metadata = file_set.file_metadata.find { |fm| file_identifier.id.include? fm.id.id }
        return file_metadata.original_filename.first if file_metadata
      end

      def default_storage_adapter
        self.class.default_storage_adapter
      end
  end
end
