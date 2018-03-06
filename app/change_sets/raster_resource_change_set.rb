# frozen_string_literal: true
class RasterResourceChangeSet < Valhalla::ChangeSet
  apply_workflow(BookWorkflow)
  delegate :human_readable_type, to: :model

  include GeoChangeSetProperties
  include VisibilityProperty
  include RemoteMetadataProperty
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates :visibility, :rights_statement, presence: true

  def apply_remote_metadata_directly?
    true
  end

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    [
      :title,
      :source_metadata_identifier,
      :rights_statement,
      :rights_note,
      :coverage,
      :local_identifier,
      :member_of_collection_ids,
      :append_id,
      :description,
      :subject,
      :spatial,
      :temporal,
      :issued,
      :creator,
      :language,
      :cartographic_scale,
      :cartographic_projection
    ]
  end
  # rubocop:enable Metrics/MethodLength
end
