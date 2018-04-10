# frozen_string_literal: true
class SimpleResourceChangeSet < Valhalla::ChangeSet
  delegate :human_readable_type, to: :model

  include VisibilityProperty
  property :title, multiple: true, required: true, default: []
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"
  property :pdf_type, multiple: false, required: false, default: "gray"
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates_with TitleValidator
  validates :visibility, :rights_statement, presence: true

  def primary_terms
    [
      :title,
      :rights_statement,
      :rights_note,
      :local_identifier,
      :pdf_type,
      :portion_note,
      :nav_date,
      :member_of_collection_ids,
      :append_id
    ]
  end
end
