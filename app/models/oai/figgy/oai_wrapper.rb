# frozen_string_literal: true
module OAI::Figgy
  class OAIWrapper < SimpleDelegator
    def to_marc21
      MarcRecordEnhancer.for(resource).enhance_cicognara.to_xml.to_s
    end

    def creator
      decorated_resource.creator || decorated_resource.imported_creator
    end

    def publisher
      decorated_resource.publisher || decorated_resource.imported_publisher
    end

    def date
      decorated_resource.created || decorated_resource.imported_created
    end

    def rights
      ControlledVocabulary.for(:rights_statement).find(decorated_resource.rights_statement.first).label
    end

    def formats
      mime_types + extents
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

      def resource
        __getobj__
      end

      def decorated_resource
        __getobj__.decorate
      end

      def mime_types
        file_sets = decorated_resource.file_sets
        return file_sets.flat_map(&:mime_type).uniq unless file_sets.empty?
        Wayfinder.for(resource).deep_file_sets.flat_map(&:mime_type).uniq
      end

      def extents
        decorated_resource.extent || decorated_resource.imported_extent || []
      end
  end
end
