# frozen_string_literal: true
class MemoryEfficientAllQuery
  def self.queries
    [:memory_efficient_all]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def memory_efficient_all(except_models: [])
    orm_class.transaction do
      relation = orm_class
      relation = relation.where.not(internal_resource: Array(except_models).map(&:to_s)) if except_models.present?
      relation.find_each.lazy.map do |object|
        resource_factory.to_resource(object: object)
      end
    end
  end
end
