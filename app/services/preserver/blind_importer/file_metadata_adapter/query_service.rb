# frozen_string_literal: true

class Preserver::BlindImporter::FileMetadataAdapter
  # This is a small version of a Valkyrie QueryService purely used to support
  # the read-only requirements of Preserver::BlindImporter.
  class QueryService
    delegate :storage_adapter, :resource_processor, to: :adapter
    attr_reader :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def find_by(id:)
      file = storage_adapter.find_by(id: storage_id_from_resource_id(id))
      json = JSON.parse(file.read)
      attributes = Valkyrie::Persistence::Shared::JSONValueMapper.new(json).result.symbolize_keys
      resource_processor.call(resource: Valkyrie::Types::Anything[attributes], adapter: adapter)
    rescue Valkyrie::StorageAdapter::FileNotFound
      raise Valkyrie::Persistence::ObjectNotFoundError
    end

    def find_members(resource:)
      member_ids = resource.try(:member_ids) || []
      member_ids.lazy.map do |id|
        file = storage_adapter.find_by(id: storage_id_from_resource_id(id, parent_resource: resource))
        json = JSON.parse(file.read)
        attributes = Valkyrie::Persistence::Shared::JSONValueMapper.new(json).result.symbolize_keys
        member = Valkyrie::Types::Anything[attributes]
        member.loaded[:parents] = [resource]
        resource_processor.call(resource: member, adapter: adapter)
      rescue Valkyrie::StorageAdapter::FileNotFound
        nil
      end.select(&:present?)
    end

    def storage_id_from_resource_id(id, parent_resource: nil, original_filename: nil)
      ancestors = find_ancestors(parent_resource)
      path = storage_adapter.path_generator.generate(
        resource: FileMetadataResource.new(id: id, new_record: false, ancestors: ancestors),
        file: nil,
        original_filename: original_filename || "#{id}.json"
      )
      "#{path_prefix}://#{path}"
    end

    def find_ancestors(parent_resource)
      return [] unless parent_resource
      grandparents = parent_resource.loaded[:parents] || []
      ([parent_resource] + grandparents.flat_map { |grandparent| find_ancestors(grandparent) }).reverse
    end

    # TODO: I wonder if Valkyrie could provide some method of doing this?
    def path_prefix
      storage_adapter.is_a?(Valkyrie::Storage::Disk) ? "disk" : "shrine"
    end

    # Cloud Storage has file identifiers which are for our local repository.
    # This converts them to be their preservation counterparts.
    class ConvertLocalStorageIDs
      def self.call(resource:, adapter:)
        new(resource: resource, adapter: adapter).convert!
      end

      delegate :storage_adapter, :query_service, to: :adapter
      delegate :storage_id_from_resource_id, to: :query_service
      attr_reader :resource, :adapter
      def initialize(resource:, adapter:)
        @resource = resource
        @adapter = adapter
      end

      def convert!
        return resource unless resource.try(:file_metadata).present?
        resource.file_metadata.map! do |file_metadata|
          file_metadata.file_identifiers.map! do |identifier|
            get_file_id(identifier, file_metadata)
          end.compact!
          file_metadata
        end
        resource.file_metadata = resource.file_metadata.select { |x| x.file_identifiers.present? }
        resource
      end

      def get_file_id(identifier, file_metadata)
        preservation_location = storage_id_from_resource_id(resource.id, parent_resource: resource.loaded[:parents]&.first, original_filename: original_filename(identifier, file_metadata))
        begin
          storage_adapter.find_by(id: preservation_location).id
        rescue Valkyrie::StorageAdapter::FileNotFound
          nil
        end
      end

      def original_filename(identifier, file_metadata)
        original_filename = Pathname.new(identifier.to_s).basename.to_s.split(".")
        "#{original_filename[0]}-#{file_metadata.id}.#{original_filename[1]}"
      end
    end
  end
end
