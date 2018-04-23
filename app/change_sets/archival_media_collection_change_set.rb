# frozen_string_literal: true
class ArchivalMediaCollectionChangeSet < Valkyrie::ChangeSet
  include RemoteMetadataProperty
  delegate :human_readable_type, to: :model

  property :source_metadata_identifier, multiple: false, required: true
  property :visibility, multiple: false, required: false

  validates_with SourceMetadataIdentifierValidator

  def primary_terms
    [:source_metadata_identifier]
  end
end
