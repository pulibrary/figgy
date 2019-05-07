# frozen_string_literal: true
class NumismaticPersonWayfinder < BaseWayfinder
  def people_count
    @people_count = query_service.custom_queries.count_all_of_model(model: NumismaticPerson)
  end
end
