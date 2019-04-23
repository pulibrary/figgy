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
      fs_attributes = import_metadata(metadata_file_identifier)

      files = import_binary_nodes(binary_file_identifiers)
      fs_attributes[:files] = files unless files.empty?
      fs = FileSet.new
      fs_change_set = FileSetChangeSet.new(fs)
      fs_change_set.validate(fs_attributes)
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

      def build_file_set_attributes(json)
        return unless json.key?("id")

        id = build_id(json["id"])
        json["id"] = id

        optimistic_lock_tokens = json["optimistic_lock_token"].map do |lock_json|
          build_optimistic_lock_token(lock_json)
        end
        json["optimistic_lock_token"] = optimistic_lock_tokens

        fs_attributes = json.symbolize_keys
        fs_attributes.delete(:file_metadata)
        fs_attributes
      end

      def import_metadata(file_identifier)
        return {} if file_identifier.nil?
        file = storage_adapter.find_by(id: file_identifier)

        file_contents = file.read
        metadata_json = JSON.parse(file_contents)
        build_file_set_attributes(metadata_json)
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
