# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`

# A scanned resource is the parent object for most digital objects that
# go into figgy.
# A ScannedResource might have one of 3 different change sets to allow different
# metadata or workflow:
#   - ScannedResourceChangeSet - metadata from an external system
#   - RecordingChangeSet - external metadata, unique workflow
#   - SimpleResourceChangeSet - local-only metadata, unique workflow
class ScannedResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
  # Store the type of change set used to create the resource
  attribute :change_set, Valkyrie::Types::String
  attribute :archival_collection_code, Valkyrie::Types::String
  attribute :date_range
  attribute :sender, Valkyrie::Types::Array.of(NameWithPlace).meta(ordered: true)
  attribute :recipient, Valkyrie::Types::Array.of(NameWithPlace).meta(ordered: true)
  attribute :upload_set_id, Valkyrie::Types::ID

  def self.can_have_manifests?
    true
  end

  def to_s
    "#{human_readable_type}: #{title&.to_sentence}"
  end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def pdf_file
    file_metadata.find do |file|
      file.mime_type == ["application/pdf"]
    end
  end

  def title
    imported_metadata&.first&.title.present? ? imported_metadata&.first&.title : __attributes__[:title]
  end

  # Determines if this is an image resource
  # @return [TrueClass, FalseClass]
  def image_resource?
    change_set != "recording"
  end

  def recording?
    change_set == "recording"
  end

  def linked_resource
    case change_set
    when "simple"
      LinkedData::LinkedSimpleResource.new(resource: self)
    else
      LinkedData::LinkedImportedResource.new(resource: self)
    end
  end
end
