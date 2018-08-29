# frozen_string_literal: true
class ScannedMap < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Geo
<<<<<<< HEAD
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
=======
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.member(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)
>>>>>>> d8616123... adds lux order manager to figgy
  attribute :relation

  def self.can_have_manifests?
    true
  end

  # How is this used?
  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  def pdf_file
    file_metadata.find do |file|
      file.mime_type == ["application/pdf"]
    end
  end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  # Determines if this is a geospatial resource
  # @return [TrueClass, FalseClass]
  def geo_resource?
    true
  end

  def title
    imported_title = primary_imported_metadata.title.present? ? primary_imported_metadata.title : []
    @title.present? ? @title : imported_title
  end
end
