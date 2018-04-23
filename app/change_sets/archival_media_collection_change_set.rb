# frozen_string_literal: true
class ArchivalMediaCollectionChangeSet < Valkyrie::ChangeSet
  include RemoteMetadataProperty
  delegate :human_readable_type, to: :model

  property :source_metadata_identifier, multiple: false, required: true
  property :bag_path, multiple: false, required: true, virtual: true
  property :visibility, multiple: false, required: false

  validates :source_metadata_identifier, presence: true
  validates_with SourceMetadataIdentifierValidator
  validates_with BagPathValidator

  def primary_terms
    [:source_metadata_identifier, :bag_path]
  end
end
