# frozen_string_literal: true
module OAI::Figgy
  class OAIWrapper < SimpleDelegator
    def to_marc21
      MarcRecordEnhancer.for(resource).enhance_cicognara.to_xml.to_s
    end

    def creator
      decorated_resource.creator || decorated_resource.imported_creator
    end

    def contributor
      decorated_resource.contributor || decorated_resource.imported_contributor
    end

    def publisher
      decorated_resource.publisher || decorated_resource.imported_publisher
    end

    def date
      decorated_resource.created || decorated_resource.imported_created
    end

    def description
      decorated_resource.description || decorated_resource.imported_description
    end

    def rights
      ControlledVocabulary.for(:rights_statement).find(decorated_resource.rights_statement.first).label
    end

    def language
      english_names = decorated_resource.language || decorated_resource.imported_language
      return unless english_names.present?
      ISO_639.find_by_english_name(english_names.first).alpha3
    end

    def formats
      mime_types + extents
    end

    def types
      content_types + genre_types
    end

    def content_types
      values = Array.wrap(decorated_resource.content_type || decorated_resource.imported_content_type)
      return ["text"] if values.empty?
      values.map do |content_type|
        content_type_map[content_type.downcase]
      end
    end

    # map of non-text values; if it's not here use "text"
    def content_type_map
      Hash.new("text").tap do |h|
        h["audio"] = "sound"
        h["visual material"] = "image"
        h["video"] = "video"
        h["musical score"] = "sound"
        h["map"] = "image"
      end
    end

    def genre_types
      Array.wrap(decorated_resource.type || decorated_resource.imported_type).map(&:downcase)
    end

    def source
      "Princeton University Library, #{decorated_resource.source_metadata_identifier&.first || resource.id}"
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
