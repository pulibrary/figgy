# frozen_string_literal: true

class SortingIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    {
      title_ssort: sort_title
    }
  end

  def sort_title
    return resource.sort_title if resource.try(:sort_title)
    return resource.title.first.to_s.downcase if resource.try(:title) && resource.title.first
    resource.id.to_s
  end
end
