# frozen_string_literal: true
module Numismatics
  class ArtistWayfinder < BaseWayfinder
    def decorated_person
      return if resource.person_id.blank?
      query_service.find_by(id: resource.person_id.first)
    rescue Valkyrie::Persistence::ObjectNotFoundError
      nil
    end
  end
end
