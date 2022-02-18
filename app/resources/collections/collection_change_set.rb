# frozen_string_literal: true

class CollectionChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  include RemoteMetadataProperty
  delegate :human_readable_type, to: :model
  property :title, multiple: false, required: true
  property :slug, multiple: false, required: true
  property :source_metadata_identifier, required: true, multiple: false
  property :description, multiple: false, required: false
  property :visibility, multiple: false, required: false
  property :owners, multiple: true, required: false
  property :restricted_viewers, multiple: true, required: false
  validates :slug, presence: true
  validates_with UniqueSlugValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator

  def primary_terms
    [:title, :slug, :source_metadata_identifier, :description, :owners, :restricted_viewers]
  end
end
