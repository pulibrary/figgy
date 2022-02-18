# frozen_string_literal: true

FactoryBot.define do
  factory :ephemera_field do
    field_name "1"
    member_of_vocabulary_id "test id"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
