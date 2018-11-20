# frozen_string_literal: true
class NumismaticMonogramWayfinder < BaseWayfinder
  relationship_by_property :file_sets, property: :member_ids, model: FileSet
end
