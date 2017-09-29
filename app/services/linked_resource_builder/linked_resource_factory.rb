# frozen_string_literal: true
class LinkedResourceBuilder
  class LinkedResourceFactory
    delegate :query_service, to: :metadata_adapter

    def initialize(resource:)
      @resource = resource
    end

    def resource
      if @resource.is_a? Valkyrie::ID
        @resource = find_resource(id: @resource)
      else
        @resource
      end
    end

    def new
      case resource
      when EphemeraFolder
        LinkedEphemeraFolder.new(resource: resource)
      when EphemeraVocabulary
        LinkedEphemeraVocabulary.new(resource: resource)
      when EphemeraTerm
        LinkedEphemeraTerm.new(resource: resource)
      when String
        LinkedNode.new(resource: resource)
      when NilClass
        Literal.new(value: resource)
      else
        LinkedResource.new(resource: resource)
      end
    end

    private

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
