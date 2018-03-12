# frozen_string_literal: true
class FindFixityFailures
  def self.queries
    [:find_fixity_failures]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_fixity_failures
    internal_array = { file_metadata: [{ fixity_success: 0 }] }.to_json
    run_query(query, internal_array)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ?
    SQL
  end

  def run_query(query, *args)
    orm_class.find_by_sql(([query] + args)).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
