# frozen_string_literal: true
class NumismaticFirmWayfinder < BaseWayfinder
  def firms_count
    @firms_count = query_service.custom_queries.count_all_of_model(model: NumismaticFirm)
  end
end
