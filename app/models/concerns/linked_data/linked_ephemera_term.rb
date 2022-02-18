# frozen_string_literal: true

module LinkedData
  class LinkedEphemeraTerm < LinkedVocabularyBase
    def self.new(resource:)
      if resource.respond_to?(:uri)
        super(resource: resource)
      else
        Literal.new(value: resource)
      end
    end

    private

      def vocabulary_properties
        return {} unless vocabulary && !resource.is_a?(EphemeraVocabulary)
        {
          "in_scheme" => LinkedEphemeraVocabulary.new(resource: vocabulary).without_context
        }
      end

      def type
        if resource.is_a?(EphemeraVocabulary)
          "skos:ConceptScheme"
        else
          "skos:Concept"
        end
      end

      def properties
        {
          '@type': type,
          pref_label: try(:label)
        }.merge!(vocabulary_properties).merge!(exact_match)
      end
  end
end
