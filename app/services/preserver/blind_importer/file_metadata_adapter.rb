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
  end
end
