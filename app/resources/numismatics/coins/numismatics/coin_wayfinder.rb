# frozen_string_literal: true

module Numismatics
  class CoinWayfinder < BaseWayfinder
    relationship_by_property :members, property: :member_ids
    relationship_by_property :file_sets, property: :member_ids, model: FileSet
    relationship_by_property :find_places, property: :find_place_id, singular: true
    relationship_by_property :collections, property: :member_of_collection_ids
    relationship_by_property :numismatic_accessions, property: :numismatic_accession_id, singular: true
    inverse_relationship_by_property :parents, property: :member_ids, singular: true

    def members_with_parents
      @members_with_parents ||= members.map do |member|
        member.loaded[:parents] = [resource]
        member
      end
    end
  end
end
