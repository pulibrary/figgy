# frozen_string_literal: true
class ScannedResourceChangeSet < ChangeSet
  apply_workflow(WorkflowRegistry.workflow_for(ScannedResource))
  delegate :human_readable_type, to: :model

  include VisibilityProperty
  include RemoteMetadataProperty
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"
<<<<<<< HEAD
  property :pdf_type, multiple: false, required: false, default: "color"
=======
  property :pdf_type, multiple: false, required: false, default: "gray"
>>>>>>> d8616123... adds lux order manager to figgy
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
<<<<<<< HEAD
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.of(Structure), default: [Structure.new(label: "Logical", nodes: [])]
=======
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.member(Structure), default: [Structure.new(label: "Logical", nodes: [])]
>>>>>>> d8616123... adds lux order manager to figgy
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false
  property :ocr_language, multiple: true, require: false, default: []

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates_with MemberValidator
  validates_with CollectionValidator
  validates :visibility, :rights_statement, presence: true

  def primary_terms
    [
      :title,
      :source_metadata_identifier,
<<<<<<< HEAD
      :member_of_collection_ids,
=======
>>>>>>> d8616123... adds lux order manager to figgy
      :rights_statement,
      :rights_note,
      :local_identifier,
      :holding_location,
      :pdf_type,
      :ocr_language,
      :portion_note,
      :nav_date,
<<<<<<< HEAD
=======
      :member_of_collection_ids,
>>>>>>> d8616123... adds lux order manager to figgy
      :append_id
    ]
  end
end
