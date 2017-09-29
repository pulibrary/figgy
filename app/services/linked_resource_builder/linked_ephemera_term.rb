# frozen_string_literal: true
class LinkedResourceBuilder
  class LinkedEphemeraTerm < LinkedResource
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

      def vocabulary_attributes
        return {} unless vocabulary
        {
          in_scheme: {
            '@id': vocabulary.try(:uri),
            pref_label: vocabulary.try(:label)
          }
        }
      end

      def attributes
        {
          '@id': internal_url,
          '@type': 'skos:Concept',
          pref_label: try(:label),
          exact_match: exact_match
        }.merge!(vocabulary_attributes)
      end
  end
end
