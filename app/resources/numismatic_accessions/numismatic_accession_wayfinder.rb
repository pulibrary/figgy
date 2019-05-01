# frozen_string_literal: true
class NumismaticAccessionWayfinder < BaseWayfinder
  relationship_by_property :firms, property: :firm_id, singular: true
  relationship_by_property :people, property: :person_id, singular: true
end
