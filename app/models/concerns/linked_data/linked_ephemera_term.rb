# frozen_string_literal: true
module LinkedData
  class LinkedEphemeraTerm < LinkedResource
    def self.new(resource:)
      if resource.respond_to?(:uri)
        super(resource: resource)
      else
        Literal.new(value: resource)
      end
    end

    delegate(
      :uri,
      :internal_url,
      :external_uri_exists?,
      :label,
      :vocabulary,
      to: :decorated_resource
    )

    def local_fields
      super.tap do |fields|
        fields.merge!(attributes).reject { |_, v| v.nil? || v.try(:empty?) }
      end
    end

    def obj_url
      helper.url_for(resource)
    end

    def basic_jsonld
      {}
    end

    def without_context
      as_jsonld.except("@context")
    end

    private

      def exact_match
        return unless external_uri_exists?
        { "@id" => Array.wrap(uri).first }
      end

      def vocabulary_attributes
        return {} unless vocabulary
        {
          "in_scheme" => self.class.new(resource: vocabulary).without_context
        }
      end

      def attributes
        {
          '@type': 'skos:Concept',
          pref_label: try(:label),
          exact_match: exact_match
        }.merge!(vocabulary_attributes)
      end
  end
end
