# frozen_string_literal: true
class FacetIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.try(:primary_imported_metadata)
    {
      display_subject_ssim: resource.primary_imported_metadata.subject,
      display_language_ssim: imported_language
    }
  end

  def imported_language
    decorated_resource.try(:display_imported_language)
  end

  def decorated_resource
    @decorated_resource ||= resource.decorate
  end
end
