# frozen_string_literal: true
# Superclass for most LinkedData resources. Provides a generic implementation
# for `#to_jsonld` and `#as_jsonld`. Subclasses are expected to override
# `#properties`
module LinkedData
  class LinkedResource
    # rubocop:disable all
    def self.for(resource:)
      if resource.is_a? Valkyrie::ID
        begin
          resource_node = ChangeSetPersister.default.query_service.find_by(id: resource)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          resource_node = nil
        end
      else
        resource_node = resource
      end
      return LinkedSimpleResource.new(resource: resource_node) if resource_node.try(:change_set) == "simple"
      # Ideal replacement: resource_node.linked_resource
      # This is called Replace Conditional with Polymorphism:
      # https://refactoring.guru/replace-conditional-with-polymorphism
      case resource_node
      when EphemeraFolder
        LinkedEphemeraFolder.new(resource: resource_node)
      when EphemeraVocabulary
        LinkedEphemeraVocabulary.new(resource: resource_node)
      when EphemeraTerm
        LinkedEphemeraTerm.new(resource: resource_node)
      when ScannedResource || ScannedMap || VectorResource
        LinkedImportedResource.new(resource: resource_node)
      when NilClass
        Literal.new(value: resource_node)
      else
        LinkedResource.new(resource: resource_node)
      end
    end
    # rubocop:enable all

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
      resource.title.map do |title|
        if title.is_a?(RDF::Literal)
          title
        else
          RDF::Literal.new(title, language: :eng)
        end
      end
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
          '@type': "dcterms:RightsStatement",
          pref_label: ControlledVocabulary.for(:rights_statement).find(resource.rights_statement.first).label
        }
      end

      def linked_collections
        return [] if resource.try(:member_of_collection_ids).blank?
        collections.map { |collection| LinkedCollection.new(resource: collection).as_jsonld }
      end

      # @note It's expected that subclasses will override this to provide more
      # terms.
      def properties
        { title: try(:title) }
      end

      # Default set of properties every JSON-LD serialization should have. Add
      # to this if you need to add more defaults.
      def linked_properties
        {
          "@context": [
            "https://bibdata.princeton.edu/context.json",
            {
              "wgs84": "http://www.w3.org/2003/01/geo/wgs84_pos#",
              "latitude": {
                "@id": "wgs84:lat"
              },
              "longitude": {
                "@id": "wgs84:lon"
              }
            }
          ],
          '@id': url,
          identifier: resource.try(:identifier),
          scopeNote: resource.try(:portion_note),
          navDate: resource.try(:nav_date),
          edm_rights: linked_rights,
          memberOf: linked_collections,
          system_created_at: resource.try(:created_at),
          system_updated_at: resource.try(:updated_at)
        }.merge(properties)
      end
  end
end
