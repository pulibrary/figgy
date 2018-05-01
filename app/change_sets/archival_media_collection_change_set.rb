# frozen_string_literal: true
class ArchivalMediaCollectionChangeSet < Valhalla::ChangeSet
  apply_workflow(WorkflowRegistry.workflow_for(ArchivalMediaCollection))
  delegate :human_readable_type, to: :model

  include RemoteMetadataProperty
  property :source_metadata_identifier, multiple: false, required: true
  property :bag_path, multiple: false, required: true, virtual: true
  property :visibility, multiple: false, required: false
  property :depositor, multiple: false, required: false, virtual: true

  validates :source_metadata_identifier, presence: true
  validates_with BagPathValidator
  validates_with SourceMetadataIdentifierValidator

  def primary_terms
    [:source_metadata_identifier, :bag_path]
  end
end
