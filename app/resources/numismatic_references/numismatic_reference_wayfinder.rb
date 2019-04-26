# frozen_string_literal: true
class NumismaticReferenceWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :numismatic_references, property: :member_ids, model: NumismaticReference
  relationship_by_property :authors, property: :author_id
  inverse_relationship_by_property :parents, property: :member_ids, singular: true

  def members_with_parents
    @members_with_parents ||= members.map do |member|
      member.loaded[:parents] = [resource]
      member
    end
  end
end
