# frozen_string_literal: true
# ArchivalMediaCollections are a legacy construct that was used for ingesting
# bags of AV material from vendors. Since then we've moved to using Bulk Ingest
# for that, but haven't removed this because we aren't sure it's no longer
# needed.
# @TODO Remove this.
class ArchivalMediaCollectionChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  delegate :human_readable_type, to: :model

  include RemoteMetadataProperty
  include VisibilityProperty

  property :source_metadata_identifier, multiple: false, required: true
  property :title, multiple: false, required: false
  property :slug, multiple: false, required: true
  property :bag_path, multiple: false, required: false, virtual: true
  # require visibility so imported resources can inherit
  property :visibility, multiple: false, required: true, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  property :depositor, multiple: false, required: false, virtual: true
  property :read_groups, multiple: true, required: false
  property :change_set, require: true, default: "archival_media_collection"
  property :embargo_date, multiple: false, required: false, type: ::Types::EmbargoDate.optional

  property :reorganize, virtual: true, require: false, default: false, type: Dry::Types["params.bool"]

  validates :source_metadata_identifier, presence: true
  validates_with BagPathValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with UniqueArchivalMediaComponentIdValidator
  validates_with UniqueArchivalMediaBarcodeValidator
  validates_with UniqueSlugValidator
  validates_with ProcessedValidator

  def primary_terms
    [
      :source_metadata_identifier,
      :slug,
      :bag_path,
      :change_set,
      :reorganize
    ]
  end
end
