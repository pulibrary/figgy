# frozen_string_literal: true

module Numismatics
  class ProvenanceChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :date, multiple: false, required: false
    property :firm_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :note, multiple: false, required: false
    property :person_id, multiple: false, required: false, type: Valkyrie::Types::ID

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
        :date,
        :note,
        :person_id,
        :firm_id
      ]
    end
  end
end
