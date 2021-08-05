# frozen_string_literal: true
class FacetIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    if resource.try(:imported_metadata)&.first
      {
        display_subject_ssim: resource.imported_metadata.first.subject,
        display_language_ssim: imported_language,
        has_structure_bsi: structure?,
        pub_date_start_itsi: pub_date_start
      }
    else
      {
        display_subject_ssim: subject_terms,
        display_language_ssim: language_terms,
        has_structure_bsi: structure?
      }
    end
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
    return unless date.present?
    date = parse_date(date.first)
    return unless date
    date.year
  end

  def parse_date(date)
    return date if date.is_a?(Time)
    Time.zone.parse(date)
  rescue TypeError, ArgumentError
    nil
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end
end
