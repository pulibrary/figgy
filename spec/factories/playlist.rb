# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    title "My Playlist"
    state "draft"
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end

    transient do
      recording []
      user nil
    end

    after(:create) do |resource, evaluator|
      if evaluator.recording.present?
        change_set = PlaylistChangeSet.new(resource)
        change_set.validate(file_set_ids: [evaluator.recording.decorate.file_sets.map(&:id)])
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end

    factory :complete_playlist do
      state "complete"
    end
  end
end
