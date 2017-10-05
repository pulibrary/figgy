# frozen_string_literal: true
class FindByStringProperty
  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_string_property(property:, value:)
    internal_array = "[\"#{value}\"]"
    run_query(query, property, internal_array)
  end

  def query
    <<-SQL
      select * FROM orm_resources WHERE
      metadata->? @> ?
    SQL
  end

  def run_query(query, *args)
    orm_class.find_by_sql(([query] + args)).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
