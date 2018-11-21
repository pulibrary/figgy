# frozen_string_literal: true
class NumismaticAccessionWayfinder < BaseWayfinder
  relationship_by_property :numismatic_citations, property: :numismatic_citation_ids, singular: false
end
