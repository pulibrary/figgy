# frozen_string_literal: true

module Numismatics
  class MonogramChangeSet < ChangeSet
    delegate :human_readable_type, to: :model

    property :title, multiple: false, required: true

    property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :files, virtual: true, multiple: true, required: false
    property :pending_uploads, multiple: true, required: false
    property :replaces, multiple: true, required: false, default: []
    property :start_canvas, required: false
    property :viewing_direction, required: false
    property :viewing_hint, multiple: false, required: false, default: "individuals"
    property :depositor, multiple: false, required: false

    def primary_terms
      [
        :title
      ]
    end
  end
end
