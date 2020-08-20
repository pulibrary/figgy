# frozen_string_literal: true
class EphemeraFolderChangeSetBase < ChangeSet
  apply_workflow(FolderWorkflow)
  enable_claiming
  validate :subject_present
  validates_with StateValidator
  validates_with RightsStatementValidator
  validates_with MemberValidator
  validates_with CollectionValidator

  include VisibilityProperty
  include DateRangeProperty
  property :title, multiple: false, required: true
  property :sort_title, required: false
  property :alternative_title, multiple: true, required: false
  property :transliterated_title, multiple: true, required: false
  property :language, multiple: true, required: true
  property :genre, multiple: false, required: true
  property :page_count, multiple: false, required: true
  property :series, multiple: true, required: false
  property :creator, multiple: false, required: false
  property :contributor, multiple: true, required: false
  property :publisher, multiple: true, required: false
  property :geographic_origin, multiple: false, required: false
  property :subject, multiple: true, required: true
  property :geo_subject, multiple: true, required: false
  property :description, multiple: false, required: false
  property :date_created, multiple: false, required: false
  property :provenance, multiple: false, required: false
  property :dspace_url, multiple: false, required: false
  property :source_url, multiple: false, required: false
  property :downloadable, multiple: false, require: true, default: "public"
  property :rights_statement, multiple: false, required: true, default: RightsStatements.copyright_not_evaluated, type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, default: [], type: Types::Strict::Array.of(Valkyrie::Types::ID.optional)
  property :member_ids, multiple: true, required: false, type: Types::Strict::Array.of(Valkyrie::Types::ID.optional)
  property :read_groups, multiple: true, required: false
  property :depositor, multiple: false, require: false
  property :ocr_language, multiple: true, require: false, default: []
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false
  property :append_id, virtual: true, multiple: false, required: false
  property :keywords, multiple: true, required: false

  property :start_canvas, required: false
  property :viewing_direction, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"

  # pdf properties
  property :file_metadata, multiple: true, required: false, default: []
  property :holding_location, multiple: false, required: false, type: ::Types::URI
  property :pdf_type, multiple: false, required: false, default: "color"

  property :local_identifier, multiple: false, required: false

  # Skip Validation
  property :skip_validation, virtual: true, type: ::Types::Bool, default: false

  delegate :human_readable_type, to: :model

  def primary_terms
    [
      :append_id,
      :barcode,
      :folder_number,
      :title,
      :sort_title,
      :alternative_title,
      :transliterated_title,
      :language,
      :genre,
      :width,
      :height,
      :page_count,
      :ocr_language,
      :keywords,
      :series,
      :creator,
      :contributor,
      :publisher,
      :geographic_origin,
      :subject,
      :geo_subject,
      :description,
      :date_created,
      :date_range_form,
      :provenance,
      :dspace_url,
      :source_url,
      :downloadable,
      :pdf_type,
      :holding_location,
      :rights_statement,
      :member_of_collection_ids
    ]
  end

  def valid?
    return true if skip_validation == true
    super
  end

  def genre=(genre_value)
    return super(genre_value) if genre_value.blank?
    super(coerce_string_value(genre_value))
  end

  def geo_subject=(geo_subject_values)
    return super(geo_subject_values) if geo_subject_values.blank?
    super(geo_subject_values.map { |geo_subject_value| coerce_string_value(geo_subject_value) })
  end

  def geographic_origin=(geographic_origin_value)
    return super(geographic_origin_value) if geographic_origin_value.blank?
    super(coerce_string_value(geographic_origin_value))
  end

  def language=(language_values)
    return super(language_values) if language_values.blank?
    super(language_values.map { |language_value| coerce_string_value(language_value) })
  end

  def subject=(subject_values)
    return super(subject_values) if subject_values.blank?
    super(subject_values.map { |subject_value| coerce_string_value(subject_value) })
  end

  def preserve?
    state == "complete"
  end

  private

    def metadata_adapter
      Valkyrie.config.metadata_adapter
    end
    delegate :query_service, to: :metadata_adapter

    def valid_id?(value)
      query_service.find_by(id: Valkyrie::ID.new(value))
      true
    rescue Valkyrie::Persistence::ObjectNotFoundError
      false
    end

    def coerce_string_value(value)
      if value.is_a?(String) && valid_id?(value)
        Valkyrie::ID.new(value)
      else
        value
      end
    end

    def subject_present
      return if Array.wrap(subject).find(&:present?)
      errors.add(:subject, "must be provided.")
    end
end
