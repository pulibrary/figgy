# frozen_string_literal: true
class CollectionChangeSet < ChangeSet
  apply_workflow(DraftCompleteWorkflow)
  include RemoteMetadataProperty
  delegate :human_readable_type, to: :model
  property :title, multiple: false, required: true
  property :slug, multiple: false, required: true
  property :source_metadata_identifier, required: true, multiple: false
  property :tagline, multiple: false, required: false
  property :description, multiple: false, required: false
  property :visibility, multiple: false, required: false
  property :owners, multiple: true, required: false
  property :restricted_viewers, multiple: true, required: false
  property :publish, multiple: false, required: false, type: Valkyrie::Types::Bool
  validates :slug, presence: true
  validates_with UniqueSlugValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator

  def primary_terms
    [:title, :slug, :publish, :source_metadata_identifier, :owners, :restricted_viewers, :description, :tagline]
  end

  def preserve?
    true
  end

  # Render fields with rich text editor
  def rich_text?(key)
    return unless key == :description
    true
  end
end
