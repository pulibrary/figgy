# frozen_string_literal: true
class EphemeraFolderChangeSet < Valkyrie::ChangeSet
  validates :barcode, :folder_number, :title, :language, :genre, :width, :height, :page_count, :visibility, :rights_statement, presence: true
  property :barcode, multiple: false, required: true
  property :folder_number, multiple: false, required: true
  property :title, multiple: false, required: true
  property :sort_title, required: false
  property :alternative_title, multiple: true, required: false
  property :language, multiple: true, required: true
  property :genre, multiple: false, required: true
  property :width, multiple: false, required: true
  property :height, multiple: false, required: true
  property :page_count, multiple: false, required: true
  property :series, multiple: false, required: false
  property :creator, required: false
  property :contributor, multiple: true, required: false
  property :publisher, multiple: true, required: false
  property :geographic_origin, required: false
  property :subject, multiple: true, required: false
  property :geo_subject, multiple: true, required: false
  property :description, required: false
  property :date_created, required: false
  property :dspace_url, required: false
  property :source_url, required: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false
  property :visibility, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
  delegate :human_readable_type, to: :model

  def primary_terms
    [
      :barcode,
      :folder_number,
      :title,
      :sort_title,
      :alternative_title,
      :language,
      :genre,
      :width,
      :height,
      :page_count,
      :rights_statement,
      :series,
      :creator,
      :contributor,
      :publisher,
      :geographic_origin,
      :subject,
      :geo_subject,
      :description,
      :date_created,
      :dspace_url,
      :source_url,
      :append_id
    ]
  end

  def visibility=(visibility)
    super.tap do |_result|
      case visibility
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        self.read_groups = [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      when Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        self.read_groups = []
      end
    end
  end
end
