# frozen_string_literal: true

class EphemeraVocabularyWayfinder < BaseWayfinder
  relationship_by_property :parent_vocabularies, property: :member_of_vocabulary_id, singular: true
  inverse_relationship_by_property :vocabularies, property: :member_of_vocabulary_id, singular: true, model: EphemeraVocabulary
  inverse_relationship_by_property :ephemera_terms, property: :member_of_vocabulary_id, singular: true, model: EphemeraTerm
end
