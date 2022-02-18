# frozen_string_literal: true

class Preserver::BlindImporter
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
