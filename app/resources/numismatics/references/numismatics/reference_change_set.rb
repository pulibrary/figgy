# frozen_string_literal: true

module Numismatics
  class ReferenceChangeSet < Valkyrie::ChangeSet
    delegate :human_readable_type, to: :model

    property :part_of_parent, multiple: false, required: false
    property :pub_info, multiple: false, required: false
    property :short_title, multiple: false, required: true
    property :title, multiple: false, required: true
    property :year, multiple: false, required: false
    property :replaces, multiple: true, required: false, default: []

    property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :author_id, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
    property :depositor, multiple: false, required: false

    def primary_terms
      [
        :author_id,
        :part_of_parent,
        :pub_info,
        :short_title,
        :title,
        :year,
        :append_id
      ]
    end
  end
end
