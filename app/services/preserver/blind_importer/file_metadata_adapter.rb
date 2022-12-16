# frozen_string_literal: true
class Preserver::BlindImporter
  # This provides the interface for a MetadataAdapter, powered by a storage adapter.
  # It knows how to use a storage adapter to find things for a query_service.
  class FileMetadataAdapter
    attr_reader :storage_adapter, :resource_processor
    def initialize(storage_adapter:, resource_processor: QueryService::ConvertLocalStorageIDs)
      @storage_adapter = storage_adapter
      @resource_processor = resource_processor
    end

    def query_service
      @query_service ||= QueryService.new(adapter: self)
    end
  end
end
