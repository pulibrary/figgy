# frozen_string_literal: true

FactoryBot.define do
  factory :numismatic_place, class: Numismatics::Place do
    city "city"
    geo_state "state"
    region "region"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
