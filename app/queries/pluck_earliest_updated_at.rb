# frozen_string_literal: true
class PluckEarliestUpdatedAt
  def self.queries
    [:pluck_earliest_updated_at]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def pluck_earliest_updated_at
    resource = orm_class.select(:updated_at).order(:updated_at).limit(1).first || {}
    resource[:updated_at]
  end
end
