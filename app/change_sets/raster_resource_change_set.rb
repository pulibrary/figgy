# frozen_string_literal: true
class RasterResourceChangeSet < ChangeSet
  apply_workflow(GeoWorkflow)
  enable_claiming
  delegate :human_readable_type, to: :model

  include GeoChangeSetProperties
  include VisibilityProperty
  include RemoteMetadataProperty
  property :title, multiple: true, required: true, default: []
  property :source_metadata_identifier, required: true, multiple: false
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID.optional)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID.optional)
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false
  property :portion_note, multiple: false, required: false
  property :downloadable, multiple: false, require: true, default: "public"
  property :embargo_date, multiple: false, required: false, type: Valkyrie::Types::String.optional

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with StateValidator
  validates_with SourceMetadataIdentifierValidator
  validates_with SourceMetadataIdentifierOrTitleValidator
  validates_with MemberValidator
  validates_with CollectionValidator
  validates_with RightsStatementValidator
  validates_with EmbargoDateValidator
  validates :visibility, presence: true

  # rubocop:disable Metrics/MethodLength
  def primary_terms
    {
      "" => [
        :title,
        :source_metadata_identifier,
        :downloadable,
        :rights_statement,
        :rights_note,
        :thumbnail_id,
        :portion_note,
        :local_identifier,
        :holding_location,
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
        :cartographic_projection,
        :coverage,
        :held_by,
        :embargo_date
      ],
      "Geospatial Web Service Overrides" => [
        :wms_url,
        :layer_name
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
