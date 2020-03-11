# frozen_string_literal: true
class FindByProperty
  def self.queries
    [:find_by_property]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  delegate :run_query, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_property(property:, value:, model: nil, lazy: false)
    relation = orm_class.use_cursor.where(Sequel[:metadata].pg_jsonb.contains(property => Array.wrap(value)))
    relation = relation.where(internal_resource: model.to_s) if model
    relation = relation.lazy if lazy
    relation.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
