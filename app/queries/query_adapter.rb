# frozen_string_literal: true
class QueryAdapter
  def initialize(query_service:)
    @query_service = query_service
  end

  def all
    @query_service.find_all
  end
end
