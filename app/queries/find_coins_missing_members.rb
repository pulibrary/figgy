class FindCoinsMissingMembers
  def self.queries
    [:find_coins_missing_members]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_property(property:, value:)
    internal_array = { property => Array.wrap(value) }
    run_query(query, internal_array.to_json)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> { "member_ids": [] }
    SQL
  end

end
