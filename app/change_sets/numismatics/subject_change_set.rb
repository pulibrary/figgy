# frozen_string_literal: true
module Numismatics
  class SubjectChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :type, multiple: false, required: false
    property :subject, multiple: false, required: false

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
        :type,
        :subject
      ]
    end
  end
end
