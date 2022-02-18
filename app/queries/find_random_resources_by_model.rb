# frozen_string_literal: true

class FindRandomResourcesByModel
  def self.queries
    [:find_random_resources_by_model]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :resources, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_random_resources_by_model(limit:, model:)
    return [] if limit.zero?
    resources.use_cursor.where(internal_resource: model.to_s).order(Sequel.function(:random)).limit(limit).lazy.map do |attributes|
      resource_factory.to_resource(object: attributes)
    end
  end
end
