# frozen_string_literal: true
class MemoryEfficientAllQuery
  def self.queries
    [:memory_efficient_all, :count_all_except_models]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def memory_efficient_all(except_models: [], order: false)
    connection.transaction(savepoint: true) do
      relation = orm_class.use_cursor
      relation = relation.exclude(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation = relation.order(Sequel.asc(:created_at)) if order
      relation.lazy.map do |object|
        resource_factory.to_resource(object: object)
      end
    end
  end

  def count_all_except_models(except_models: [])
    connection.transaction(savepoint: true) do
      relation = orm_class.use_cursor
      relation = relation.exclude(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation.count
    end
  end
end
