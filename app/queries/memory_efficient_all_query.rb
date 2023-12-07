# frozen_string_literal: true
class MemoryEfficientAllQuery
  def self.queries
    [:memory_efficient_all, :memory_efficient_find_many_by_ids, :count_all_except_models]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :adapter, to: :query_service
  delegate :connection, to: :adapter
  delegate :resources, to: :adapter
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def memory_efficient_all(except_models: [], order: false, since: nil)
    connection.transaction(savepoint: true) do
      relation = orm_class.use_cursor
      relation = relation.exclude(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation = relation.order(Sequel.asc(:created_at)) if order
      relation = relation.where { created_at > since } if since
      relation.lazy.map do |object|
        resource_factory.to_resource(object: object)
      end
    end
  end

  def memory_efficient_find_many_by_ids(ids:)
    ids.lazy.map do |id|
      connection.transaction(savepoint: true) do
        attributes = resources.first(id: id.to_s)
        resource_factory.to_resource(object: attributes)
      end
    end
  end

  def count_all_except_models(except_models: [], since: nil)
    connection.transaction(savepoint: true) do
      relation = orm_class.use_cursor
      relation = relation.exclude(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation = relation.where { created_at > since } if since
      relation.count
    end
  end
end
