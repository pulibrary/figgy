# frozen_string_literal: true
module Numismatics
  class ReferenceWayfinder < BaseWayfinder
    relationship_by_property :members, property: :member_ids
    relationship_by_property :numismatic_references, property: :member_ids, model: Numismatics::Reference
    relationship_by_property :authors, property: :author_id
    inverse_relationship_by_property :parents, property: :member_ids, singular: true

    def members_with_parents
      @members_with_parents ||= members.map do |member|
        member.loaded[:parents] = [resource]
        member
      end
    end

    def references_count
      @references_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Reference)
    end
  end
end
