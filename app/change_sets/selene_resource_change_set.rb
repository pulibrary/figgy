# frozen_string_literal: true
class SeleneResourceChangeSet < ChangeSet
  apply_workflow(BookWorkflow)
  delegate :human_readable_type, to: :resource

  include VisibilityProperty
  property :visibility, multiple: false, required: true, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :title, multiple: true, required: true, default: ["Selene"]
  property :rights_statement, multiple: false, required: true, default: RightsStatements.copyright_not_evaluated, type: ::Types::URI
  property :downloadable, multiple: false, require: true, default: "none"
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :change_set, require: true, default: "selene_resource"
  property :depositor, multiple: false, require: false

  property :pending_uploads, multiple: true, required: false
  property :portion_note, multiple: false, required: false
  property :meters_per_pixel, multiple: false, required: true, type: ::Types::Params::Float.optional

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false # Used for attaching files.
  property :ingest_path, virtual: true, multiple: false, required: true
  property :deletion_marker_restore_ids, virtual: true, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID), default: [] # Used for preservation restoration.

  validates_with StateValidator
  validates_with MemberValidator
  validates_with ProcessedValidator
  validates_with TitleValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :title,
      :ingest_path,
      :portion_note,
      :change_set,
      :append_id
    ]
  end

  def preserve?
    persisted? && state == "complete"
  end
end
