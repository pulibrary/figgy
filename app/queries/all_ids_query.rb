# frozen_string_literal: true

class AllIdsQuery
  def self.queries
    [:all_ids]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :orm_class, to: :resource_factory

  def initialize(query_service:)
    @query_service = query_service
  end

  def all_ids(except_models: [])
    connection.transaction(savepoint: true) do
      relation = orm_class.use_cursor
      relation = relation.select(:id)
      relation = relation.exclude(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation.lazy.map { |r| r[:id] }
    end
  end
end
