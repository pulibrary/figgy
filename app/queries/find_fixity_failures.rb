# frozen_string_literal: true

class FindFixityFailures
  def self.queries
    [:find_fixity_failures]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_fixity_failures
    internal_array = {file_metadata: [{fixity_success: 0}]}.to_json
    run_query(query, internal_array)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ?
    SQL
  end
end
