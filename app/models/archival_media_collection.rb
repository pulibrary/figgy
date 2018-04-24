# frozen_string_literal: true
class ArchivalMediaCollection < Collection
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :source_metadata_identifier

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : ['']
  end
end
