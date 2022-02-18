# frozen_string_literal: true

module Bagit
  class QueryService
    attr_reader :adapter
    def initialize(adapter:)
      @adapter = adapter
    end

    def find_by(id:)
      raise ArgumentError, "id must be a Valkyrie::ID" unless id.is_a?(Valkyrie::ID) || id.is_a?(String)
      id = Valkyrie::ID.new(id.to_s)
      loader = Bagit::BagLoader.new(adapter: adapter, id: id)
      raise Valkyrie::Persistence::ObjectNotFoundError unless loader.exist?
      loader.load!
    end

    def find_by_alternate_identifier(alternate_identifier:)
      raise ArgumentError, "alternate_identifier must be a Valkyrie::ID" unless alternate_identifier.is_a?(Valkyrie::ID) || alternate_identifier.is_a?(String)
      Valkyrie.logger.warn("Bagit Query Service has been asked to find a resource by its alternate identifier. This will require iterating over the metadata of every bag - AVOID.")
      alternate_identifier = Valkyrie::ID.new(alternate_identifier.to_s)
      output = find_all.find do |resource|
        next unless resource.respond_to?(:alternate_ids)
        resource.alternate_ids.include?(alternate_identifier)
      end
      raise Valkyrie::Persistence::ObjectNotFoundError unless output.present?
      output
    end

    def find_many_by_ids(ids:)
      ids.uniq.map do |id|
        find_by(id: id)
      rescue ::Valkyrie::Persistence::ObjectNotFoundError
        nil
      end.reject(&:nil?)
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

    def find_references_by(resource:, property:, model: nil)
      ids = (resource.try(property) || []).select { |id| id.is_a?(Valkyrie::ID) }
      ids.uniq! unless resource.class.fields.include?(property) && resource.ordered_attribute?(property)
      resources = ids.lazy.map do |id|
        find_by(id: id)
      end
      filter_by_model(resources, model)
    end

    def find_all_of_model(model:)
      Valkyrie.logger.warn("Bagit Query Service has been asked to find all resources of a specific type. This will require iterating over the metadata of every bag - AVOID.")
      find_all.select do |resource|
        resource.is_a?(model)
      end
    end

    def count_all_of_model(model:)
      Valkyrie.logger.warn("Bagit Query Service has been asked to find all resources of a specific type. This will require iterating over the metadata of every bag - AVOID.")
      find_all_of_model(model: model).to_a.length
    end

    def find_inverse_references_by(property:, resource: nil, id: nil, model: nil)
      raise ArgumentError, "Provide resource or id" unless resource || id
      raise ArgumentError, "resource is not saved" unless !resource || resource.persisted?
      Valkyrie.logger.warn("Bagit Query Service has been asked to find inverse references. This will require iterating over the metadata of every bag - AVOID.")
      id ||= resource.id
      resources = find_all.select do |potential_inverse_reference|
        (potential_inverse_reference.try(property) || []).include?(id)
      end
      filter_by_model(resources, model)
    end

    def custom_queries
      @custom_queries ||= ::Valkyrie::Persistence::CustomQueryContainer.new(query_service: self)
    end

    private

      def filter_by_model(resources, model)
        return resources unless model
        resources.select { |found_resource| found_resource.instance_of?(model) }
      end
  end
end
