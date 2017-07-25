# frozen_string_literal: true
class ScannedResourceChangeSet < Valkyrie::ChangeSet
  delegate :human_readable_type, to: :model
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :rights_statement, multiple: false, required: true
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false
  property :pdf_type, multiple: false, required: false
  property :holding_location, multiple: false, required: false
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :visibility, multiple: false, default: [Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE]
  property :local_identifier, multiple: true, required: false, default: []
  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator

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
end
