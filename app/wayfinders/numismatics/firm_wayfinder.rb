# frozen_string_literal: true
module Numismatics
  class FirmWayfinder < BaseWayfinder
    def firms_count
      @firms_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Firm)
    end
  end
end
