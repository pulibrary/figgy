# frozen_string_literal: true
class Collection < Resource
  include Valkyrie::Resource::AccessControls
  attribute :title, Valkyrie::Types::Set
  attribute :slug, Valkyrie::Types::Set
  attribute :source_metadata_identifier, Valkyrie::Types::Set
  attribute :imported_metadata, Valkyrie::Types::Set.of(ImportedMetadata).optional
  attribute :description, Valkyrie::Types::Set
  attribute :visibility, Valkyrie::Types::Set
  attribute :local_identifier, Valkyrie::Types::Set
  attribute :owners, Valkyrie::Types::Set # values should be User.uid

  def thumbnail_id; end

  def primary_imported_metadata
    Array.wrap(imported_metadata).first || ImportedMetadata.new
  end

  def title
    primary_imported_metadata.title.present? ? primary_imported_metadata.title : @title
  end
end
