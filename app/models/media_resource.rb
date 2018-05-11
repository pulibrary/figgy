# frozen_string_literal: true
# Generated with `rails generate valkyrie:model MediaResource`
class MediaResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids, Valkyrie::Types::Set
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional
  attribute :state

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : @title
  end
end
