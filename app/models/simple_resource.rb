# frozen_string_literal: true
# This is a Class for scanned resources with only locally-provided metadata
class SimpleResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids

  attribute :state
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)

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
end
