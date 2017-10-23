# frozen_string_literal: true
module LinkedData
  class LinkedResource
    attr_reader :resource
    delegate(
      :collections,
      to: :decorated_resource
    )

    def initialize(resource:)
      @resource = resource
    end

    def as_jsonld
      linked_properties.reject { |_, v| v.nil? || v.try(:empty?) }.stringify_keys
    end

    def to_jsonld
      as_jsonld.to_json
    end
    alias to_json to_jsonld
    alias to_s to_json

    def without_context
      as_jsonld.except("@context")
    end

    def title
      Array.wrap(decorated_resource.title).first
    end

    private

      def decorated_resource
        @decorated_resource ||= resource.decorate
      end

      def helper
        @helper ||= ManifestBuilder::ManifestHelper.new
      end

      def url
        @url ||= helper.solr_document_url(id: resource.id)
      end

      def linked_rights
        return if resource.try(:rights_statement).blank?
        {
          '@id': resource.rights_statement.first.to_s,
          '@type': 'dcterms:RightsStatement',
          pref_label: ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first).label
        }
      end

      def linked_collections
        return [] if resource.try(:member_of_collection_ids).blank?
        collections.map { |collection| LinkedCollection.new(resource: collection).as_jsonld }
      end

      def properties
        { title: try(:title) }
      end

      def linked_properties
        {
          '@context': 'https://bibdata.princeton.edu/context.json',
          '@id': url,
          identifier: resource.try(:identifier),
          scopeNote: resource.try(:portion_note),
          navDate: resource.try(:nav_date),
          edm_rights: linked_rights,
          memberOf: linked_collections
        }.merge(properties)
      end
  end
end
