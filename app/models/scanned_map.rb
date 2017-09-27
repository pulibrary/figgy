# frozen_string_literal: true
class ScannedMap < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Geo
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.member(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)

  def self.can_have_manifests?
    true
  end

  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  def primary_imported_metadata
    Array.wrap(self).first
  end
end
