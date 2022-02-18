# frozen_string_literal: true

module Numismatics
  class FirmChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :city, multiple: false, required: false
    property :name, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []
    property :depositor, multiple: false, required: false

    def primary_terms
      [
        :name,
        :city
      ]
    end
  end
end
