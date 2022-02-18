# frozen_string_literal: true

FactoryBot.define do
  factory :ephemera_project do
    title "Test Project"
    slug "test_project-1234"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
