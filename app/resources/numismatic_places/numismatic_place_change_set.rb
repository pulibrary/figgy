# frozen_string_literal: true
class NumismaticPlaceChangeSet < ChangeSet
  delegate :human_readable_type, to: :model

  property :city, multiple: false, required: false
  property :geo_state, multiple: false, required: false
  property :region, multiple: false, required: false
  property :replaces, multiple: true, required: false, default: []

  def primary_terms
    [
      :city,
      :geo_state,
      :region
    ]
  end
end
