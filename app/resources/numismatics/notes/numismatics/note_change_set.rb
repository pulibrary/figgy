# frozen_string_literal: true
module Numismatics
  class NoteChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

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
        :note,
        :type
      ]
    end
  end
end
