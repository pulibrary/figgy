# frozen_string_literal: true
class ScannedResourceChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model
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
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.member(Structure), default: [Structure.new(label: "Logical", nodes: [])]
  property :state, multiple: false, required: true, default: BookWorkflow.aasm.initial_state.to_s

  # Virtual Attributes
  property :refresh_remote_metadata, virtual: true, multiple: false
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validate :source_metadata_identifier_or_title
  validate :source_metadata_identifier_valid
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
      :state,
      :member_of_collection_ids
    ]
  end

  # Validate that either the source_metadata_identifier or the title is set.
  def source_metadata_identifier_or_title
    return if source_metadata_identifier.present? || Array.wrap(title).first.present?
    errors.add(:title, "You must provide a source metadata id or a title")
    errors.add(:source_metadata_identifier, "You must provide a source metadata id or a title")
  end

  def source_metadata_identifier_valid
    return unless apply_remote_metadata?
    return if RemoteRecord.retrieve(Array(source_metadata_identifier).first).success?
    errors.add(:source_metadata_identifier, "Error retrieving metadata")
  end

  def apply_remote_metadata?
    source_metadata_identifier.present? && (!persisted? || refresh_remote_metadata == "1")
  end

  def workflow
    workflow_class.new(state.first)
  end

  def workflow_class
    BookWorkflow
  end
end
