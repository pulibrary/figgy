# frozen_string_literal: true
module Numismatics
  class MonogramWayfinder < BaseWayfinder
    relationship_by_property :members, property: :member_ids
    relationship_by_property :file_sets, property: :member_ids, model: FileSet

    def members_with_parents
      @members_with_parents ||= members.map do |member|
        member.loaded[:parents] = [resource]
        member
      end
    end

    def monograms_count
      @monograms_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Monogram)
    end
  end
end
