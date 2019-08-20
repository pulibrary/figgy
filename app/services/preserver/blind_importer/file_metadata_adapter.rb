# frozen_string_literal: true
class Preserver::BlindImporter
  class FileMetadataAdapter
    attr_reader :storage_adapter, :parents, :resource_processor
    def initialize(storage_adapter:, parents: [], resource_processor: QueryService::ConvertLocalStorageIDs)
      @storage_adapter = storage_adapter
      @parents = parents
      @resource_processor = resource_processor
    end

    def query_service
      @query_service ||= QueryService.new(adapter: self)
    end

    def with_context(parent:, **_args)
      self.class.new(storage_adapter: storage_adapter, parents: parents + [parent])
    end
  end
end
