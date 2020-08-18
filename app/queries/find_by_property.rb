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

  # Find by an arbitrary property. If property is :metadata, then value should
  # be a hash to query for the value of multiple properties.
  def find_by_property(property:, value:, model: nil, lazy: false)
    relation = orm_class.use_cursor
    if property.to_sym != :metadata
      relation = relation.where(Sequel[:metadata].pg_jsonb.contains(property => Array.wrap(value)))
    else
      # Wrap all the values in the hash in an array, since that's how they're
      # stored.
      value = Hash[value.map { |k, v| [k, Array.wrap(v)] }]
      relation = orm_class.where(Sequel[:metadata].pg_jsonb.contains(value))
    end
    relation = relation.where(internal_resource: model.to_s) if model
    relation = relation.lazy if lazy
    relation.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
