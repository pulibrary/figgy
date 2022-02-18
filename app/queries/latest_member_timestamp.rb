# frozen_string_literal: true

class LatestMemberTimestamp
  def self.queries
    [:latest_member_timestamp]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def latest_member_timestamp(resource:)
    query_service.connection[query, id: resource.id.to_s].first[:latest_updated]
  end

  def query
    <<-SQL
      select MAX(member.updated_at) AS latest_updated
      FROM orm_resources a,
      jsonb_array_elements(a.metadata->'member_ids') AS b(member)
      JOIN orm_resources member ON (b.member->>'id')::UUID = member.id
      WHERE a.id = :id
    SQL
  end
end
