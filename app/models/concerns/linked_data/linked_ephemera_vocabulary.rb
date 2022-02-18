# frozen_string_literal: true

module LinkedData
  class LinkedEphemeraVocabulary < LinkedVocabularyBase
    private

      def properties
        {
          '@id': internal_url,
          '@type': "skos:ConceptScheme",
          pref_label: try(:label)
        }.merge!(exact_match)
      end
  end
end
