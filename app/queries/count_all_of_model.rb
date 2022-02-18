# frozen_string_literal: true

class CountAllOfModel
  def self.queries
    [:count_all_of_model]
  end

  attr_reader :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  def initialize(query_service:)
    @query_service = query_service
  end

  # @param model [Class] Model to count
  def count_all_of_model(model:)
    connection[find_all_query, model.to_s].first[:count]
  end

  def find_all_query
    <<-SQL
      SELECT COUNT(*) AS count FROM orm_resources a
      WHERE internal_resource = ?
    SQL
  end
end
