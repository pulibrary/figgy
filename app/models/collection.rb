# frozen_string_literal: true
class Collection < Resource
  include Valkyrie::Resource::AccessControls
  include Schema::Common
  attribute :slug, Valkyrie::Types::Set
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :owners, Valkyrie::Types::Set # values should be User.uid
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :change_set, Valkyrie::Types::String
  attribute :restricted_viewers, Valkyrie::Types::Set

  def thumbnail_id; end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.presence || attributes[:title]
  end
end
