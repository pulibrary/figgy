# frozen_string_literal: true
class RecordingChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  enable_structure_manager
  enable_claiming
  delegate :human_readable_type, to: :resource

  include VisibilityProperty
  include RemoteMetadataProperty
  property :visibility, multiple: false, required: true, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :title, multiple: true, required: true, default: []
  property :downloadable, multiple: false, require: true, default: "none"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :source_metadata_identifier, multiple: false, required: false
  property :read_groups, multiple: true, required: false
  property :change_set, require: true, default: "recording"
  property :part_of, require: false, default: []
  property :upload_set_id, multiple: false, require: false, type: Valkyrie::Types::ID
  property :embargo_date, multiple: false, required: false, type: Valkyrie::Types::Date

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
      :source_metadata_identifier,
      :title,
      :downloadable,
      :rights_statement,
      :member_of_collection_ids,
      :local_identifier,
      :part_of,
      :append_id,
      :change_set,
      :embargo_date
    ]
  end

  # Do not preserve Audio Reserves recordings
  def preserve?
    return false unless persisted?
    if in_archival_media_collection?
      true
    else
      false
    end
  end

  private

    def in_archival_media_collection?
      collections = Wayfinder.for(resource).collections
      collections.each do |collection|
        return true if collection.change_set == "archival_media_collection"
      end

      false
    end
end
