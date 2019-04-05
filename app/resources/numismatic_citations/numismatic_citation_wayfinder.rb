# frozen_string_literal: true
class NumismaticCitationWayfinder < BaseWayfinder
  define_singular_relation(:numismatic_references)

  def numismatic_references
    resource.numismatic_reference_id.map do |id|
      query_service.find_by(id: id)
    end
  end
end
