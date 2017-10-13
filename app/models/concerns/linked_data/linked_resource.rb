# frozen_string_literal: true
module LinkedData
  class LinkedResource
    attr_reader :resource
    delegate(
      :title,
      :collections,
      to: :decorated_resource
    )

    def initialize(resource:)
      @resource = resource
    end

    def basic_jsonld
      {
        title: try(:title)
      }
    end

    def imported_jsonld
      return basic_jsonld unless resource.respond_to?(:primary_imported_metadata) && resource.primary_imported_metadata.source_jsonld.present?
      @imported_jsonld ||= JSON.parse(resource.primary_imported_metadata.source_jsonld.first)
    end

    def helper
      @helper ||= ManifestBuilder::ManifestHelper.new
    end

    def obj_url
      helper.solr_document_url(id: resource.id)
    end

    def local_fields
      {
        '@context': 'https://bibdata.princeton.edu/context.json',
        '@id': obj_url,
        identifier: resource.try(:identifier),
        scopeNote: resource.try(:portion_note),
        navDate: resource.try(:nav_date),
        edm_rights: rights_object,
        memberOf: collection_objects
      }.reject { |_, v| v.nil? || v.try(:empty?) }
    end

    def as_json(_options = nil)
      imported_jsonld.merge(local_fields)
    end

    def without_context(values = nil)
      values ||= as_json
      values.reject { |k, _| k == :'@context' }
    end

    def to_jsonld
      imported_jsonld.merge(local_fields).to_json
    end
    alias to_json to_jsonld
    alias to_s to_json

    private

      def rights_object
        return if resource.try(:rights_statement).blank?
        {
          '@id': resource.rights_statement.first.to_s,
          '@type': 'dcterms:RightsStatement',
          pref_label: ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first).label
        }
      end

      def decorated_resource
        @decorated_resource ||= resource.decorate
      end

      def collection_objects
        return [] if resource.try(:member_of_collection_ids).blank?
        collections.map do |collection|
          {
            '@id': helper.solr_document_url(id: collection.id),
            '@type': 'pcdm:Collection',
            title: collection.title
          }
        end
      end
  end
end
