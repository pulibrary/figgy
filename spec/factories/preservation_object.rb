# frozen_string_literal: true

FactoryBot.define do
  factory :preservation_object do
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
