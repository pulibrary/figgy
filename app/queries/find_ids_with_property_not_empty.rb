# frozen_string_literal: true

class FindIdsWithPropertyNotEmpty
  def self.queries
    [:find_ids_with_property_not_empty]
  end

  attr_reader :query_service
  delegate :resources, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def find_ids_with_property_not_empty(property:)
    relation = {property => []}
    metadata = Sequel.pg_jsonb_op(:metadata)
    resources.select(:id).where(
      metadata.has_key?(property.to_s)
    ).where(
      metadata.contains(relation)
    ).use_cursor.lazy.map do |x|
      Valkyrie::ID.new(x[:id])
    end
  end
end
