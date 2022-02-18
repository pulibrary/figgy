# frozen_string_literal: true

class FindSavedIds
  def self.queries
    [:find_saved_ids]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_saved_ids(ids:)
    ids = ids.map(&:to_s).select do |id|
      Valkyrie::Sequel::QueryService::ACCEPTABLE_UUID.match?(id)
    end
    orm_class.where(id: ids).pluck(:id).map do |id|
      Valkyrie::ID.new(id)
    end
  end
end
