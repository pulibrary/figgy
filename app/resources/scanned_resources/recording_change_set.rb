# frozen_string_literal: true
class RecordingChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  delegate :human_readable_type, to: :resource

  include VisibilityProperty
  include RemoteMetadataProperty
  property :visibility, multiple: false, required: true, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :title, multiple: true, required: true, default: []
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :source_metadata_identifier, multiple: false, required: false
  property :read_groups, multiple: true, required: false
  property :change_set, require: true, default: "recording"

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with MemberValidator
  validates_with CollectionValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :rights_statement,
      :member_of_collection_ids,
      :local_identifier,
      :append_id,
      :change_set
    ]
  end
end
