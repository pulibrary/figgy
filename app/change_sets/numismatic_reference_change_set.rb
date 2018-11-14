# frozen_string_literal: true
class NumismaticReferenceChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model

  property :author, multiple: true, required: false, default: []
  property :part_of_parent, multiple: false, required: false
  property :pub_info, multiple: false, required: false
  property :short_title, multiple: false, required: true
  property :title, multiple: false, required: true
  property :year, multiple: false, required: false

  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)

  def primary_terms
    [
      :author,
      :part_of_parent,
      :pub_info,
      :short_title,
      :title,
      :year,
      :append_id
    ]
  end
end
