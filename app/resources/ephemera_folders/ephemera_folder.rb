# frozen_string_literal: true

class EphemeraFolder < Resource
  include Valkyrie::Resource::AccessControls
  attribute :member_ids, Valkyrie::Types::Array
  attribute :barcode, Valkyrie::Types::Set
  attribute :folder_number, Valkyrie::Types::Set
  attribute :title, Valkyrie::Types::Set
  attribute :sort_title, Valkyrie::Types::Set
  attribute :alternative_title, Valkyrie::Types::Set
  attribute :transliterated_title, Valkyrie::Types::Set
  attribute :language, Valkyrie::Types::Set
  attribute :genre
  attribute :width, Valkyrie::Types::Set
  attribute :height, Valkyrie::Types::Set
  attribute :page_count, Valkyrie::Types::Set
  attribute :rights_statement
  attribute :rights_note, Valkyrie::Types::Set
  attribute :member_of_collection_ids
  attribute :logical_structure, Valkyrie::Types::Array.of(Structure.optional).optional
  attribute :pending_uploads, Valkyrie::Types::Array.of(PendingUpload)
  attribute :series, Valkyrie::Types::Set
  attribute :creator, Valkyrie::Types::Set
  attribute :contributor, Valkyrie::Types::Set
  attribute :publisher, Valkyrie::Types::Set
  attribute :geographic_origin
  attribute :subject, Valkyrie::Types::Set
  attribute :geo_subject, Valkyrie::Types::Set
  attribute :description, Valkyrie::Types::Set
  attribute :date_created, Valkyrie::Types::Set
  attribute :provenance, Valkyrie::Types::Set
  attribute :dspace_url
  attribute :source_url
  attribute :depositor, Valkyrie::Types::Set
  attribute :date_range
  attribute :ocr_language, Valkyrie::Types::Set
  attribute :keywords, Valkyrie::Types::Set

  attribute :start_canvas
  attribute :viewing_direction
  attribute :viewing_hint

  attribute :thumbnail_id
  attribute :visibility
  attribute :pdf_type
  attribute :local_identifier
  attribute :identifier
  attribute :downloadable

  attribute :state
  attribute :workflow_note, Valkyrie::Types::Array.of(WorkflowNote).optional
  attribute :holding_location
  attribute :claimed_by, Valkyrie::Types::String
  attribute :cached_parent_id, Valkyrie::Types::ID.optional

  def self.can_have_manifests?
    true
  end

  # Determines whether or not the "Save and Duplicate Metadata" is supported for this Resource
  # @return [Boolean]
  def self.supports_save_and_duplicate?
    true
  end

  attribute :file_metadata, Valkyrie::Types::Set.of(FileMetadata.optional)

  def pdf_file
    file_metadata.find do |file|
      file.mime_type == ["application/pdf"]
    end
  end

  def extent
    "#{Array.wrap(page_count).first} page(s)" unless page_count.empty?
  end

  # Inherit edit users from parent Project, to enable external contributors.
  def edit_users
    return self[:edit_users] unless persisted?
    (self[:edit_users] + (Wayfinder.for(self).ephemera_project&.edit_users || [])).uniq
  end

  def linked_resource
    LinkedData::LinkedEphemeraFolder.new(resource: self)
  end
end
