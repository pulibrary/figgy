# frozen_string_literal: true
module Numismatics
  class ArtistChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :person_id, multiple: false, required: false, type: Valkyrie::Types::ID
    property :signature, multiple: false, required: false
    property :role, multiple: false, required: false
    property :side, multiple: false, required: false

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
        :person_id,
        :signature,
        :role,
        :side
      ]
    end
  end
end
