# frozen_string_literal: true
# This is a Class for scanned resources with only locally-provided metadata
class SimpleResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids

  attribute :state
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional

  # Does this generate IIIF Manifests
  # @return [TrueClass, FalseClass]
  def self.can_have_manifests?
    true
  end

  # Provide the string serialization
  # @return [String]
  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  # Retrieve the PDF FileSet
  def pdf_file
    file_metadata.find do |file|
      file.mime_type == ["application/pdf"]
    end
  end

  # Determines if this is an image resource
  # @return [TrueClass, FalseClass]
  def image_resource?
    true
  end
end
