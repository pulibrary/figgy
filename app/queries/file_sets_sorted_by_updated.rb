# frozen_string_literal: true

class FileSetsSortedByUpdated
  def self.queries
    [:file_sets_sorted_by_updated]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def file_sets_sorted_by_updated(sort: "asc", limit: 50)
    order_field = sort == "asc" ? :updated_at : Sequel.desc(:updated_at)
    orm_class.where(internal_resource: "FileSet").order(order_field).limit(limit).lazy.map do |object|
      resource_factory.to_resource(object: object)
    end
  end
end
