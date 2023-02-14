# frozen_string_literal: true
FactoryBot.define do
  factory :deletion_marker do
    resource_title { "Title" }
    resource_id { Valkyrie::ID.new(SecureRandom.uuid) }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
