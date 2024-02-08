# frozen_string_literal: true
class FacetIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    if resource.try(:imported_metadata)&.first
      imported_metadata_solr_fields
    else
      solr_fields
    end
  end

  def imported_metadata_solr_fields
    {
      display_subject_ssim: resource.imported_metadata.first.subject,
      display_language_ssim: imported_language,
      has_structure_bsi: structure?,
      pub_date_start_itsi: pub_date_start,
      file_type_ssim: file_types
    }
  end

  def solr_fields
    {
      display_subject_ssim: subject_terms,
      display_language_ssim: language_terms,
      has_structure_bsi: structure?,
      file_type_ssim: file_types
    }
  end

  def imported_language
    decorated_resource.try(:display_imported_language)
  end

  def subject_terms
    terms = []
    terms.concat(decorated_resource.subject) if decorated_resource.try(:subject)
    terms.concat(decorated_resource.categories) if decorated_resource.try(:categories)
    terms.map do |term|
      term.respond_to?(:label) ? Array.wrap(term.label).first : term
    end.uniq
  end

  def language_terms
    terms = []
    terms.concat(decorated_resource.language) if decorated_resource.try(:language)
    terms.map do |term|
      term.respond_to?(:label) ? Array.wrap(term.label).first : term
    end.uniq
  end

  def structure?
    resource.logical_structure.first.nodes.length.positive?
  rescue
    false
  end

  def pub_date_start
    date = resource.imported_metadata&.first&.created
    return if date.blank?
    date = parse_date(date.first)
    return unless date
    date.year
  end

  def parse_date(date)
    return date if date.is_a?(Time) || date.is_a?(DateTime)
    Time.zone.parse(date)
  rescue TypeError, ArgumentError
    nil
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end

  def file_types
    file_sets = Wayfinder.for(resource).try(:file_sets)
    return unless file_sets
    types = file_sets.map do |file_set|
      file_metadata = file_set.original_file || file_set.intermediate_file
      file_type(file_metadata: file_metadata) if file_metadata
    end.compact.uniq

    if mosaic?
      types << "Raster Mosaic"
    else
      types
    end
  end

  def file_type(file_metadata:)
    if file_metadata.video?
      "Video"
    elsif file_metadata.audio?
      "Audio"
    end
  end

  def mosaic?
    return false unless resource.is_a?(RasterResource) || resource.is_a?(ScannedMap)
    resource.decorate.mosaic_file_count > 1
  end
end
