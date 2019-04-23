# frozen_string_literal: true
class NumismaticArtistWayfinder < BaseWayfinder
  def decorated_person
    return if resource.person_id.blank?
    query_service.find_by(id: resource.person_id.first)
  end
end
