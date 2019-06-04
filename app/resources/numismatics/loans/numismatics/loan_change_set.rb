# frozen_string_literal: true
module Numismatics
  class LoanChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :firm_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :person_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :date_in, multiple: false, required: false
    property :date_out, multiple: false, required: false
    property :exhibit_name, multiple: false, required: false
    property :note, multiple: false, required: false
    property :type, multiple: false, required: false

    # Virtual Attributes
    property :_destroy, virtual: true

    def new_record?
      false
    end

    def marked_for_destruction?
      false
    end

    def primary_terms
      [
        :firm_id,
        :person_id,
        :date_in,
        :date_out,
        :exhibit_name,
        :note,
        :type
      ]
    end
  end
end
