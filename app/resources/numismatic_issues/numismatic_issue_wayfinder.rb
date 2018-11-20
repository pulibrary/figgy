# frozen_string_literal: true
class NumismaticIssueWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :numismatic_citations, property: :numismatic_citation_ids, singular: false
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  relationship_by_property :coins, property: :member_ids, model: Coin
  relationship_by_property :collections, property: :member_of_collection_ids
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def coin_count
    @coin_count ||= query_service.custom_queries.count_members(resource: resource, model: Coin)
  end

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end
end
