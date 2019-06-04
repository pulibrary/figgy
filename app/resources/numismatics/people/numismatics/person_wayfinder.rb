# frozen_string_literal: true
module Numismatics
  class PersonWayfinder < BaseWayfinder
    def people_count
      @people_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Person)
    end
  end
end
