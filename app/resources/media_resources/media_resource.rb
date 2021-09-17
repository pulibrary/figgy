# frozen_string_literal: true
# GeneratedMediaResource with `rails generate valkyrie:model MediaResource`
class MediaResource < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids, Valkyrie::Types::Set
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :state
  attribute :upload_set_id, Valkyrie::Types::ID

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : attributes[:title]
  end

  # Determines if this is a media resource
  # @return [TrueClass, FalseClass]
  def media_resource?
    true
  end
end
