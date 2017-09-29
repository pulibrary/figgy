# frozen_string_literal: true
class ScannedResourceChangeSet < Valhalla::ChangeSet
  apply_workflow(BookWorkflow)
  delegate :human_readable_type, to: :model

  include VisibilityProperty
  include RemoteMetadataProperty
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"
  property :pdf_type, multiple: false, required: false, default: "gray"
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.member(Structure), default: [Structure.new(label: "Logical", nodes: [])]
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates :visibility, :rights_statement, presence: true

  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :rights_statement,
      :rights_note,
      :local_identifier,
      :holding_location,
      :pdf_type,
      :portion_note,
      :nav_date,
      :member_of_collection_ids,
      :append_id
    ]
  end
end
