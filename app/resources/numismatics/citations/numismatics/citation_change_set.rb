# frozen_string_literal: true

module Numismatics
  class CitationChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :citation_type, multiple: false, required: false
    property :number, multiple: false, required: false
    property :numismatic_reference_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
    property :part, multiple: false, required: false
    property :uri, multiple: false, required: false

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
        :citation_type,
        :part,
        :number,
        :numismatic_reference_id,
        :uri
      ]
    end
  end
end
