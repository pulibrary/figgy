# frozen_string_literal: true
class ArchivalMediaCollectionChangeSet < ChangeSet
  apply_workflow(WorkflowRegistry.workflow_for(ArchivalMediaCollection))
  delegate :human_readable_type, to: :model

  include RemoteMetadataProperty
  property :source_metadata_identifier, multiple: false, required: true
  property :bag_path, multiple: false, required: false, virtual: true
  # require visibility so imported resources can inherit
  property :visibility, multiple: false, required: true
  property :depositor, multiple: false, required: false, virtual: true
  property :read_groups, multiple: true, required: false

  validates :source_metadata_identifier, presence: true
  validates_with BagPathValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with UniqueArchivalMediaComponentIdValidator
  validates_with UniqueArchivalMediaBarcodeValidator

  def primary_terms
    [:source_metadata_identifier, :bag_path]
  end
end
