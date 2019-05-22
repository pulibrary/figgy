# frozen_string_literal: true
class NumismaticPlaceWayfinder < BaseWayfinder
  def places_count
    @places_count = query_service.custom_queries.count_all_of_model(model: NumismaticPlace)
  end
end
