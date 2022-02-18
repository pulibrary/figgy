# frozen_string_literal: true

class EphemeraFieldWayfinder < BaseWayfinder
  relationship_by_property :ephemera_vocabularies, property: :member_of_vocabulary_id, singular: true
  relationship_by_property :favorite_terms, property: :favorite_term_ids
  relationship_by_property :rarely_used_terms, property: :rarely_used_term_ids
  inverse_relationship_by_property :ephemera_projects, property: :member_ids, model: EphemeraProject, singular: true
end
