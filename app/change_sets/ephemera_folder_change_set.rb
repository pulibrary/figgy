# frozen_string_literal: true
class EphemeraFolderChangeSet < Valhalla::ChangeSet
  def self.new(record, *args)
    return DynamicChangeSet.new(record, *args) unless record.is_a?(EphemeraFolder)
    super
  end

  apply_workflow(FolderWorkflow)
  validates :barcode, :folder_number, :title, :language, :genre, :width, :height, :page_count, :visibility, :rights_statement, presence: true
  validate :date_range_validity
  validates_with StateValidator

  include VisibilityProperty
  property :barcode, multiple: false, required: true
  property :folder_number, multiple: false, required: true
  property :title, multiple: false, required: true
  property :sort_title, required: false
  property :alternative_title, multiple: true, required: false
  property :language, multiple: true, required: true
  property :genre, multiple: false, required: true, type: Valkyrie::Types::ID
  property :width, multiple: false, required: true
  property :height, multiple: false, required: true
  property :page_count, multiple: false, required: true
  property :series, multiple: false, required: false
  property :creator, multiple: false, required: false
  property :contributor, multiple: true, required: false
  property :publisher, multiple: true, required: false
  property :geographic_origin, multiple: false, required: false
  property :subject, multiple: true, required: false
  property :geo_subject, multiple: true, required: false
  property :description, multiple: false, required: false
  property :date_created, multiple: false, required: false
  property :provenance, multiple: false, required: false
  property :dspace_url, multiple: false, required: false
  property :source_url, multiple: false, required: false
  property :rights_statement, multiple: false, required: true, default: "http://rightsstatements.org/vocab/NKC/1.0/", type: ::Types::URI
  property :rights_note, multiple: false, required: false
  property :thumbnail_id, multiple: false, required: false, type: Valkyrie::Types::ID
  property :member_of_collection_ids, multiple: true, required: false, default: [], type: Types::Strict::Array.member(Valkyrie::Types::ID)
  property :read_groups, multiple: true, required: false
  property :files, virtual: true, multiple: true, required: false
  property :pending_uploads, multiple: true, required: false

  property :start_canvas, required: false
  property :viewing_direction, required: false
  property :viewing_hint, multiple: false, required: false, default: "individuals"

  # override the default value defined in VisibilityProperty
  property :visibility, multiple: false, default: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
  property :pdf_type, multiple: false, required: false
  property :local_identifier, multiple: false, required: false

  property :date_range, multiple: false, required: false
  property :date_range_form_attributes, virtual: true
  delegate :human_readable_type, to: :model

  def date_range_form_attributes=(attributes)
    return unless date_range_form.validate(attributes)
    date_range_form.sync
    self.date_range = date_range_form.model
  end

  def date_range_validity
    return if date_range_form.valid?
    errors.add(:date_range_form, "is not valid.")
  end

  def date_range_form
    @date_range_form ||= DynamicChangeSet.new(date_range_value || DateRange.new).tap(&:prepopulate!)
  end

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
      :date_range_form,
      :provenance,
      :dspace_url,
      :source_url,
      :append_id
    ]
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

    def date_range_value
      Array.wrap(date_range).first
    end
end
