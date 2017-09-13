# frozen_string_literal: true
FactoryGirl.define do
  factory :ephemera_project do
    name 'Test Project'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
