# frozen_string_literal: true
FactoryGirl.define do
  factory :ephemera_vocabulary do
    label 'test vocabulary'
    value 'https://example.com/ns/testVocabulary'
    member_of_vocabulary_id 'test id'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
