# frozen_string_literal: true
module Numismatics
  class FindChangeSet < Valkyrie::ChangeSet
    delegate :human_readable_type, to: :model

    property :place, multiple: false, required: false
    property :date, multiple: false, required: false
    property :find_number, multiple: false, required: false
    property :feature, multiple: false, required: false
    property :locus, multiple: false, required: false
    property :description, multiple: false, required: false

    validates_with AutoIncrementValidator, property: :find_number

    def primary_terms
      [
        :place,
        :date,
        :feature,
        :locus,
        :description
      ]
    end
  end
end
