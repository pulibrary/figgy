# frozen_string_literal: true
class RasterResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Geo

  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)

  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  # Determines if this is a geospatial resource
  # @return [TrueClass, FalseClass]
  def geo_resource?
    true
  end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    imported_title = primary_imported_metadata.title.present? ? primary_imported_metadata.title : []
    @title.present? ? @title : imported_title
  end
end
