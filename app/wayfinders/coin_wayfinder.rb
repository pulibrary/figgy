# frozen_string_literal: true
class CoinWayfinder < BaseWayfinder
  relationship_by_property :members, property: :member_ids
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
  inverse_relationship_by_property :parents, property: :member_ids, singular: true
end
