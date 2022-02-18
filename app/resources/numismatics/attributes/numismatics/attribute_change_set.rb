# frozen_string_literal: true

module Numismatics
  class AttributeChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :description, multiple: false, required: false
    property :name, multiple: false, required: false

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
        :description,
        :name
      ]
    end
  end
end
