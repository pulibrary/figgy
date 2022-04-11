# frozen_string_literal: true
module Numismatics
  class IssueWayfinder < BaseWayfinder
    relationship_by_property :masters, property: :master_id, singular: true
    relationship_by_property :members, property: :member_ids
    relationship_by_property :numismatic_places, property: :numismatic_place_id, singular: true
    relationship_by_property :rulers, property: :ruler_id
    relationship_by_property :numismatic_monograms, property: :numismatic_monogram_ids
    relationship_by_property :file_sets, property: :member_ids, model: FileSet
    relationship_by_property :coins, property: :member_ids, model: Numismatics::Coin
    relationship_by_property :collections, property: :member_of_collection_ids
    inverse_relationship_by_property :parents, property: :member_ids, singular: true

    def coin_count
      @coin_count ||= query_service.custom_queries.count_members(resource: resource, model: Numismatics::Coin)
    end

    def issues_count
      @issues_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Issue)
    end

    def members_with_parents
      @members_with_parents ||= members.map do |member|
        member.loaded[:parents] = [resource]
        member
      end
    end

    def coin_file_sets
      @coin_file_sets ||= decorated_coins.map(&:decorated_file_sets).flatten
    end
  end
end
