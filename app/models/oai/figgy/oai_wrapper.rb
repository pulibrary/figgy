# frozen_string_literal: true
module OAI::Figgy
  class OAIWrapper < SimpleDelegator
    def to_marc21
      MarcRecordEnhancer.for(__getobj__).enhance_cicognara.to_xml.to_s
    end

    def creator
      decorated_resource.creator || decorated_resource.imported_creator
    end

    def sets
      ScannedResourcesController.change_set_persister.query_service.find_references_by(resource: __getobj__, property: :member_of_collection_ids).map do |collection|
        OAI::Set.new(
          spec: collection.slug.first,
          name: collection.title.first
        )
      end
    end

    private

      def decorated_resource
        __getobj__.decorate
      end
  end
end
