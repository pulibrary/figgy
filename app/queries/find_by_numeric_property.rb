# frozen_string_literal: true
class FindByNumericProperty < FindByStringProperty
  def self.queries
    [:find_by_numeric_property]
  end

  def initialize(query_service:)
    @query_service = query_service
  end

  def find_by_numeric_property(property:, value:)
    internal_array = "{\"#{property}\": [#{value}]}"
    run_query(query, internal_array)
  end
end
