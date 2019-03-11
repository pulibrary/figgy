# frozen_string_literal: true
class NumismaticCitationWayfinder < BaseWayfinder
  relationship_by_property :numismatic_references, property: :numismatic_reference_id, singular: true
  inverse_relationship_by_property :numismatic_citation_parents, singular: true, property: :numismatic_citation_ids
end
