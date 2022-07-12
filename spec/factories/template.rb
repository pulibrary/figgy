# frozen_string_literal: true
FactoryBot.define do
  factory :template do
    title { "Test Template" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
