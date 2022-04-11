# frozen_string_literal: true
module Numismatics
  class PlaceWayfinder < BaseWayfinder
    def places_count
      @places_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Place)
    end
  end
end
