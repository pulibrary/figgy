# frozen_string_literal: true
module Bagit
  class QueryService
    attr_reader :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def find_by(id:)
      loader = Bagit::BagLoader.new(adapter: adapter, id: id)
      raise Valkyrie::Persistence::ObjectNotFoundError unless loader.exist?
      loader.load!
    end

    def find_all; end

    def find_members(resource:); end

    def find_parents(resource:); end

    def find_references_by(resource:, property:); end

    def find_all_of_model(model:); end

    def find_inverse_references_by(resource:, property:); end

    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end
  end
end
