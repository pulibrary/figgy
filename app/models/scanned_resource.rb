# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
class ScannedResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :state
  attribute :logical_structure, Valkyrie::Types::Array.member(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional

  def to_s
    "#{human_readable_type}: #{title.to_sentence}"
  end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : @title
  end
end
