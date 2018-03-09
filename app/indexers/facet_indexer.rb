# frozen_string_literal: true
class FacetIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    if resource.try(:primary_imported_metadata)
      {
        display_subject_ssim: resource.primary_imported_metadata.subject,
        display_language_ssim: imported_language
      }
    else
      {
        display_subject_ssim: subject_terms,
        display_language_ssim: language_terms
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

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end
end
