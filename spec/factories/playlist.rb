# frozen_string_literal: true
FactoryBot.define do
  factory :playlist do
    title "My Playlist"
    state "draft"
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    factory :complete_playlist do
      state "complete"
    end
  end
end
