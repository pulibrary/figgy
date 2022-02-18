# frozen_string_literal: true

class CountInverseRelationship
  def self.queries
    [:count_inverse_relationship]
  end

  attr_reader :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  def initialize(query_service:)
    @query_service = query_service
  end

  # @param resource [Valkyrie::Resource] resources whose relationship will be counted
  # @param property [Symbol] property to check the inverse relationship of
  def count_inverse_relationship(resource:, property:)
    relationship = {property => [{id: resource.id.to_s}]}
    connection[find_inverse_relationship_query, relationship.to_json].first[:count]
  end

  def find_inverse_relationship_query
    <<-SQL
      SELECT COUNT(*) AS count FROM orm_resources a
      WHERE a.metadata @> ?
    SQL
  end
end
