# frozen_string_literal: true
FactoryGirl.define do
  factory :ephemera_term do
    label 'test term'
    uri 'https://example.com/ns/testVocabulary#testTerm'
    member_of_vocabulary_id 'test id'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
