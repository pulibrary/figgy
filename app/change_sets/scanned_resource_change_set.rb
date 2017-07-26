# frozen_string_literal: true
class ScannedResourceChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :refresh_remote_metadata, virtual: true, multiple: false
  property :rights_statement, multiple: false, required: true
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false
  property :pdf_type, multiple: false, required: false
  property :holding_location, multiple: false, required: false
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :local_identifier, multiple: true, required: false, default: []
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
      :nav_date
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
    source_metadata_identifier.present? && (!persisted? || refresh_remote_metadata)
  end
end
