# frozen_string_literal: true
class TitleIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.decorate.respond_to?(:title) && resource.decorate.title.present?
    {
      figgy_title_tesim: title_strings,
      figgy_title_tesi: title_strings.first,
      figgy_title_ssim: title_strings,
      figgy_title_ssi: title_strings.first
    }
  end

  def title_strings
    # Some resources need a different title to be indexed into Solr.
    # NumismaticReference is an example. Needed for user requested drop down values.
    @title_strings ||= if resource.decorate.respond_to?(:indexed_title) && resource.decorate.indexed_title.present?
                         Array.wrap(resource.decorate.indexed_title).map(&:to_s)
                       else
                         Array.wrap(resource.decorate.title).map(&:to_s)
                       end
  end
end
