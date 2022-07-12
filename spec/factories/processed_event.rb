# frozen_string_literal: true
FactoryBot.define do
  factory :processed_event do
    event_id { "123456" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
