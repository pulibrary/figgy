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
    orm_class.where(id: ids.map(&:to_s)).pluck(:id).map do |id|
      Valkyrie::ID.new(id)
    end
  end
end
