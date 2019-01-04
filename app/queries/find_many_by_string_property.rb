
# frozen_string_literal: true
class FindManyByStringProperty
  def self.queries
    [:find_many_by_string_property]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_many_by_string_property(property:, values:)
    query = build_query(property, values)
    run_query(query)
  end

  private

    def build_conditions(property, values)
      conditions = values.map do |value|
        "metadata @> '{\"#{property}\": [\"#{value}\"]}'"
      end

      conditions.join(" OR ")
    end

    def build_query(property, values)
      conditions = build_conditions(property, values)
      <<-SQL
      select * FROM orm_resources WHERE #{conditions}
      SQL
    end
end
