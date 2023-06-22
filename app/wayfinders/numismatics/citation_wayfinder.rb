# frozen_string_literal: true
module Numismatics
  class CitationWayfinder < BaseWayfinder
    define_singular_relation(:numismatic_references)

    def numismatic_references
      resource.numismatic_reference_id.map do |id|
        query_service.find_by(id: id)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end
    end
  end
end
