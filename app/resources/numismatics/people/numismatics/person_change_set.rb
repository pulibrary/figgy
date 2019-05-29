# frozen_string_literal: true
module Numismatics
  class PersonChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :name1, multiple: false, required: false
    property :name2, multiple: false, required: false
    property :epithet, multiple: false, required: false
    property :family, multiple: false, required: false
    property :born, multiple: false, required: false
    property :died, multiple: false, required: false
    property :class_of, multiple: false, required: false
    property :years_active_start, multiple: false, required: false
    property :years_active_end, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :depositor, multiple: false, required: false

    def primary_terms
      [
        :name1,
        :name2,
        :epithet,
        :family,
        :born,
        :died,
        :class_of,
        :years_active_start,
        :years_active_end
      ]
    end
  end
end
