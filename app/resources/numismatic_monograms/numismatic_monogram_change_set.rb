# frozen_string_literal: true
class NumismaticMonogramChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model

  property :title, multiple: false, required: true

  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  def primary_terms
    [
      :title
    ]
  end
end
