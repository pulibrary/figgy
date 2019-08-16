# frozen_string_literal: true
class Preserver::BlindImporter
  class FileMetadataAdapter
    attr_reader :storage_adapter, :parents
    def initialize(storage_adapter:, parents: [])
      @storage_adapter = storage_adapter
      @parents = parents
    end

    def query_service
      @query_service ||= QueryService.new(adapter: self)
    end

    def with_parent(parent:)
      self.class.new(storage_adapter: storage_adapter, parents: parents + [parent])
    end

    class QueryService
      delegate :storage_adapter, to: :adapter
      attr_reader :adapter
      def initialize(adapter:)
        @adapter = adapter
      end

      def find_by(id:)
        file = storage_adapter.find_by(id: storage_id_from_resource_id(id))
        json = JSON.parse(file.read)
        attributes = Valkyrie::Persistence::Shared::JSONValueMapper.new(json).result.symbolize_keys
        Valkyrie::Types::Anything[attributes]
      end

      # TODO: I wonder if Valkyrie could provide some method of doing this?
      def storage_id_from_resource_id(id)
        path = storage_adapter.path_generator.generate(
          resource: FileMetadataResource.new(id: id, new_record: false, parents: adapter.parents),
          file: nil,
          original_filename: "#{id}.json"
        )
        if storage_adapter.is_a?(Valkyrie::Storage::Disk)
          "disk://#{path}"
        else
          "shrine://#{path}"
        end
      end

      class BlindImporterMetadataWayfinder < Wayfinder
        def parent
          return nil if resource.parents.blank?
          last_parent = resource.parents.last
          remaining_parents = resource.parents[0..-2]
          resource.class.new(id: last_parent.id, new_record: false, parents: remaining_parents)
        end
      end

      class FileMetadataResource < Valkyrie::Resource
        attribute :parents
      end
    end
  end
end
