# frozen_string_literal: true
module LinkedData
  class LinkedEphemeraVocabulary < LinkedResource
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

    private

      def exact_match
        return unless external_uri_exists?
        Array.wrap(uri).first
      end

      def attributes
        {
          '@id': internal_url,
          '@type': 'skos:ConceptScheme',
          pref_label: try(:label),
          exact_match: exact_match
        }
      end
  end
end
