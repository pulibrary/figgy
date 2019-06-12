# frozen_string_literal: true

class Preserver
  class Importer
    attr_reader :metadata_file_identifier, :binary_file_identifiers, :storage_adapter, :change_set_persister

    def self.default_storage_adapter
      Valkyrie::StorageAdapter.find(:google_cloud_storage)
    end

    def self.from_preservation_object(resource:, change_set_persister:, storage_adapter: nil)
      file_metadata = resource.metadata_node
      metadata_file_identifier = if file_metadata.nil?
                                   nil
                                 else
                                   file_metadata.file_identifiers.first
                                 end
      binary_nodes = resource.binary_nodes
      binary_file_identifiers = binary_nodes.map(&:file_identifiers)
      binary_file_identifiers.flatten!

      resource_storage_adapter = storage_adapter || default_storage_adapter
      instance = new(
        metadata_file_identifier: metadata_file_identifier,
        binary_file_identifiers: binary_file_identifiers,
        change_set_persister: change_set_persister,
        storage_adapter: resource_storage_adapter
      )
      instance.import!
    end

    def initialize(metadata_file_identifier:, binary_file_identifiers:, change_set_persister:, storage_adapter: nil)
      @metadata_file_identifier = metadata_file_identifier
      @binary_file_identifiers = binary_file_identifiers
      @storage_adapter = storage_adapter || default_storage_adapter
      @change_set_persister = change_set_persister
    end

    def import!
      fs = build_file_set(metadata_file_identifier)
      fs_change_set = FileSetChangeSet.new(fs)

      files = import_binary_nodes(binary_file_identifiers)
      fs_change_set.validate(files: files)

      persisted = nil
      change_set_persister.buffer_into_index do |buffered_change_set_persister|
        persisted = buffered_change_set_persister.save(change_set: fs_change_set)
      end
      persisted
    end

    private

      def build_id(json)
        Valkyrie::ID.new(json["id"])
      end

      def build_optimistic_lock_token(json)
        return unless json.key?("adapter_id")

        adapter_id = build_id(json["adapter_id"])
        token = json["token"]

        Valkyrie::Persistence::OptimisticLockToken.new(
          adapter_id: adapter_id,
          token: token
        )
      end

      def build_file_set(file_identifier)
        return {} if file_identifier.nil?
        file = storage_adapter.find_by(id: file_identifier)

        file_contents = file.read
        metadata_json = JSON.parse(file_contents)
        resource_object = { metadata: metadata_json }
        Valkyrie.config.metadata_adapter.resource_factory.to_resource(object: resource_object)
      rescue Valkyrie::StorageAdapter::FileNotFound => not_found_error
        Rails.logger.error("#{file_identifier} could not be retrieved: #{not_found_error.message}")
        {}
      end

      def import_binary_node(file_identifier)
        stored_file = storage_adapter.find_by(id: file_identifier)
        IngestableFile.new(
          file_path: stored_file.disk_path,
          mime_type: "application/octet-stream",
          original_filename: File.basename(stored_file.disk_path)
        )
      rescue Valkyrie::StorageAdapter::FileNotFound => not_found_error
        Rails.logger.error("#{file_identifier} could not be retrieved: #{not_found_error.message}")
        nil
      end

      def import_binary_nodes(file_identifiers)
        files = file_identifiers.map { |file_id| import_binary_node(file_id) }
        files.compact
      end

      def default_storage_adapter
        self.class.default_storage_adapter
      end
  end
end
