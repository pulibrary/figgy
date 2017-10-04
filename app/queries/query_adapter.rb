# frozen_string_literal: true
module QueryAdapter
  class Base
    def initialize(query_service:)
      @query_service = query_service
    end

    def all
      @query_service.find_all.lazy.to_a
    end
  end
end
