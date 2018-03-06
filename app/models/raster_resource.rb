# frozen_string_literal: true
class RasterResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Geo

  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :file_metadata, Valkyrie::Types::Set.member(FileMetadata.optional)
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)

  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  def geo_resource?
    true
  end
end
