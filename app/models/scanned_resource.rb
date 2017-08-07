# frozen_string_literal: true
# Generated with `rails generate valkyrie:model ScannedResource`
class ScannedResource < Valhalla::Resource
  include Valkyrie::Resource::AccessControls
  attribute :id, Valkyrie::Types::ID.optional
  attribute :member_ids, Valkyrie::Types::Array
  attribute :member_of_collection_ids
  attribute :imported_metadata, Valkyrie::Types::Set.member(ImportedMetadata).optional
  attribute :state
  # Books
  attribute :source_metadata_identifier
  attribute :title
  attribute :description
  attribute :visibility
  attribute :portion_note
  attribute :rights_statement
  attribute :rights_note
  attribute :holding_location
  attribute :pdf_type
  attribute :nav_date
  attribute :start_canvas
  attribute :thumbnail_id
  attribute :viewing_hint
  attribute :viewing_direction
  attribute :logical_structure, Valkyrie::Types::Array.member(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.member(PendingUpload)
  attribute :ocr_language
  attribute :identifier
  attribute :local_identifier
  # Other Fields
  attribute :sort_title
  attribute :abstract
  attribute :alternative
  attribute :replaces
  attribute :contents
  attribute :container

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
