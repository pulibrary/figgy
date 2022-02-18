# frozen_string_literal: true

module Numismatics
  class PlaceChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :city, multiple: false, required: false
    property :geo_state, multiple: false, required: false
    property :region, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :depositor, multiple: false, required: false

    def primary_terms
      [
        :city,
        :geo_state,
        :region
      ]
    end
  end
end
