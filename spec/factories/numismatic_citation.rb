# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_citation do
    part "citation part"
    number "citation number"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
