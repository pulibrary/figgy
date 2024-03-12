# frozen_string_literal: true
class FindUncaptionedMembers
  def self.queries
    [:find_uncaptioned_members]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_uncaptioned_members(resource:)
    query_service.custom_queries.find_video_members(resource: resource).select(&:missing_captions?)
  end
end
