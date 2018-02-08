# frozen_string_literal: true
module Bagit
  class QueryService
    attr_reader :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def find_by(id:)
      raise ArgumentError, 'id must be a Valkyrie::ID' unless id.is_a? Valkyrie::ID
      loader = Bagit::BagLoader.new(adapter: adapter, id: id)
      raise Valkyrie::Persistence::ObjectNotFoundError unless loader.exist?
      loader.load!
    end

    def find_all
      adapter.bag_paths.lazy.map do |bag_path|
        find_by(id: Valkyrie::ID.new(Pathname.new(bag_path).basename))
      end
    end

    def find_members(resource:, model: nil)
      find_references_by(resource: resource, property: :member_ids).select do |member|
        model.nil? || member.is_a?(model)
      end
    end

    def find_parents(resource:)
      find_inverse_references_by(resource: resource, property: :member_ids)
    end

    def find_references_by(resource:, property:)
      ids = (resource.try(property) || []).select { |id| id.is_a?(Valkyrie::ID) }
      ids.lazy.map do |id|
        find_by(id: id)
      end
    end

    def find_all_of_model(model:)
      Valkyrie.logger.warn("Bagit Query Service has been asked to find all resources of a specific type. This will require iterating over the metadata of every bag - AVOID.")
      find_all.select do |resource|
        resource.is_a?(model)
      end
    end

    def find_inverse_references_by(resource:, property:)
      Valkyrie.logger.warn("Bagit Query Service has been asked to find inverse references. This will require iterating over the metadata of every bag - AVOID.")
      return [] unless resource.id.present?
      find_all.select do |potential_inverse_reference|
        (potential_inverse_reference.try(property) || []).include?(resource.id)
      end
    end

    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end
  end
end
