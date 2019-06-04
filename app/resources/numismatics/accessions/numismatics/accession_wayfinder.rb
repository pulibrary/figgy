# frozen_string_literal: true
module Numismatics
  class AccessionWayfinder < BaseWayfinder
    relationship_by_property :firms, property: :firm_id, singular: true
    relationship_by_property :people, property: :person_id, singular: true

    def accessions_count
      @accessions_count = query_service.custom_queries.count_all_of_model(model: Numismatics::Accession)
    end
  end
end
