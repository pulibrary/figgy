# frozen_string_literal: true

FactoryBot.define do
  factory :ephemera_term do
    label "test term"
    uri "https://example.com/ns/testVocabulary#testTerm"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
