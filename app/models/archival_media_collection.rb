# frozen_string_literal: true
class ArchivalMediaCollection < Collection
  include Schema::Common
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.member(WorkflowNote).optional

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : [""]
  end
end
