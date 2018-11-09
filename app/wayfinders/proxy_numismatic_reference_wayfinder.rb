# frozen_string_literal: true
class ProxyNumismaticReferenceWayfinder < BaseWayfinder
  def numismatic_reference
    query_service.find_by(id: numismatic_reference_id)
  end

  def numismatic_reference_id
    Array.wrap(resource.numismatic_reference_id).first
  end
end
