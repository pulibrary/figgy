# frozen_string_literal: true

class FindResourcesWithExpiredEmbargoes
  def self.queries
    [:find_resources_with_expired_embargoes]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_resources_with_expired_embargoes
    run_query(query, today)
  end

  def today
    Time.zone.today.strftime("%-m/%-d/%Y")
  end

  def query
    <<-SQL
      SELECT *
      FROM orm_resources a
      WHERE (metadata ->> 'embargo_date')::date <= ?::date
    SQL
  end
end
