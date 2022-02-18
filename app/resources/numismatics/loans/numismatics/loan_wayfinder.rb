# frozen_string_literal: true

module Numismatics
  class LoanWayfinder < BaseWayfinder
    def decorated_firm
      return if resource.firm_id.blank?
      query_service.find_by(id: resource.firm_id.first)
    end

    def decorated_person
      return if resource.person_id.blank?
      query_service.find_by(id: resource.person_id.first)
    end
  end
end
