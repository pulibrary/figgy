# frozen_string_literal: true
module LinkedData
  class LinkedResourceFactory
    delegate :query_service, to: :metadata_adapter

    def initialize(resource:)
      @resource_node = resource
    end

    def new
      case resource_node
      when EphemeraFolder
        LinkedEphemeraFolder.new(resource: resource_node)
      when EphemeraVocabulary
        LinkedEphemeraVocabulary.new(resource: resource_node)
      when EphemeraTerm
        LinkedEphemeraTerm.new(resource: resource_node)
      when NilClass
        Literal.new(value: resource_node)
      else
        LinkedResource.new(resource: resource_node)
      end
    end

    private

      def resource_node
        if @resource_node.is_a? Valkyrie::ID
          @resource_node = find_resource(id: @resource_node)
        else
          @resource_node
        end
      end

      def find_resource(id:)
        query_service.find_by(id: id)
      rescue
        nil
      end

      def metadata_adapter
        Valkyrie.config.metadata_adapter
      end
  end
end
