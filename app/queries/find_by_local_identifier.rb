# frozen_string_literal: true
class FindByLocalIdentifier
  def self.queries
    [:find_by_local_identifier]
  end

  attr_reader :query_service
  delegate :resource_factory, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_local_identifier(local_identifier:)
    string_property_query.find_by_string_property(
      property: :local_identifier,
      value: local_identifier
    )
  end

  def string_property_query
    @string_property_query ||= FindByStringProperty.new(query_service: query_service)
  end
end
