# frozen_string_literal: true
class SimpleChangeSet < ChangeSet
  delegate :human_readable_type, to: :model

  apply_workflow(DraftCompleteWorkflow)
  enable_claiming

  include VisibilityProperty
  include DateRangeProperty
  property :title, multiple: true, required: true, default: []
  property :downloadable, multiple: false, require: true, default: "public"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.no_known_copyright, type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"
  property :pdf_type, multiple: false, required: false, default: "color"
  property :viewing_direction, multiple: false, required: false
  property :portion_note, multiple: false, required: false
  property :nav_date, multiple: false, required: false
  property :local_identifier, multiple: true, required: false, default: []
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID.optional
  property :start_canvas, multiple: false, type: Valkyrie::Types::ID.optional
  property :member_of_collection_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :file_metadata, multiple: true, required: false, default: []
  property :depositor, multiple: false, require: false

  # The following are editable through automated ingest, but will not show up in
  # the form until we have support for the data types in them in production.
  property :sort_title, multiple: true, required: true, default: []
  property :abstract, multiple: true, required: false, default: []
  property :alternative, multiple: true, required: false, default: []
  property :alternative_title, multiple: true, required: false, default: []
  property :archival_collection_code, multiple: false, required: false
  property :bibliographic_citation, multiple: true, required: false, default: []
  property :contents, multiple: true, required: false, default: []
  property :extent, multiple: true, required: false, default: []
  property :genre, multiple: true, required: false, default: []
  property :geo_subject, multiple: true, required: false, default: []
  property :license, multiple: true, required: false, default: []
  property :part_of, multiple: true, required: false, default: []
  property :replaces, multiple: true, required: false, default: []
  property :type, multiple: true, required: false, default: []
  property :contributor, multiple: true, required: false, default: []
  property :coverage, multiple: true, required: false, default: []
  property :coverage_point, multiple: true, required: false, default: []
  property :creator, multiple: true, required: false, default: []
  property :photographer, multiple: true, required: false, default: []
  property :actor, multiple: true, required: false, default: []
  property :director, multiple: true, required: false, default: []
  property :date, multiple: true, required: false, default: []
  property :description, multiple: true, required: false, default: []
  property :keyword, multiple: true, required: false, default: []
  property :language, multiple: true, required: false, default: []
  property :publisher, multiple: true, required: false, default: []
  property :date_published, multiple: true, required: false, default: []
  property :date_issued, multiple: true, required: false, default: []
  property :date_copyright, multiple: true, required: false, default: []
  property :source, multiple: true, required: false, default: []
  property :subject, multiple: true, required: false, default: []
  property :series, multiple: true, required: false
  property :ocr_language, multiple: true, require: false, default: []
  property :logical_structure, multiple: true, required: false, type: Types::Strict::Array.of(Structure), default: [Structure.new(label: "Logical", nodes: [])]
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :location, multiple: true, required: false, default: []
  property :date_created, multiple: false, required: false, default: []
  property :geographic_origin, multiple: false, required: false, default: []
  property :resource_type, multiple: false, required: false, default: []
  property :change_set, require: true, default: "simple"
  property :embargo_date, multiple: false, required: false, type: Valkyrie::Types::String.optional
  property :notice_type, multiple: false, required: false

  # Virtual Attributes
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  validates_with ViewingDirectionValidator
  validates_with ViewingHintValidator
  validates_with TitleValidator
  validates_with MemberValidator
  validates_with CollectionValidator
  validates_with RightsStatementValidator
  validates_with EmbargoDateValidator
  validates_with ProcessedValidator
  validates :visibility, presence: true

  def primary_terms
    [
      :title,
      :rights_statement,
      :rights_note,
      :notice_type,
      :local_identifier,
      :pdf_type,
      :downloadable,
      :ocr_language,
      :portion_note,
      :nav_date,
      :member_of_collection_ids,
      :append_id,
      :holding_location,
      :change_set,
      :embargo_date
      # The following were disabled until we have support for already-ingested
      # content that have complicated values in these fields. See #1714 and #1713
      # :sort_title,
      # :abstract,
      # :alternative,
      # :alternative_title,
      # :bibliographic_citation,
      # :contents,
      # :extent,
      # :genre,
      # :geo_subject,
      # :license,
      # :part_of,
      # :replaces,
      # :type,
      # :contributor,
      # :coverage,
      # :creator,
      # :date,
      # :description,
      # :keyword,
      # :language,
      # :publisher,
      # :date_published,
      # :date_issued,
      # :date_copyright,
      # :date_range_form,
      # :source,
      # :subject,
    ]
  end
end
