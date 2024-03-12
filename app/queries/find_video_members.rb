# frozen_string_literal: true
class FindVideoMembers
  def self.queries
    [:find_video_members]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_video_members(resource:, count: false)
    query_service.custom_queries.find_deep_children_with_property(resource: resource, model: FileSet, property: :file_metadata, value: [{ mime_type: ["video/mp4"] }], count: count)
  end
end
