# frozen_string_literal: true
FactoryBot.define do
  factory :media_resource, class: "ScannedResource" do
    title "Title"
    rights_statement RightsStatements.no_known_copyright
    read_groups "public"
    state "draft"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files []
      user nil
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
      if evaluator.visibility.present?
        change_set = RecordingChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    factory :complete_media_resource do
      state "complete"
    end
    factory :media_resource_with_audio_file do
      after(:build) do |resource, _evaluator|
        resource.member_ids ||= []
        resource.member_ids += [FactoryBot.create_for_repository(:audio_file_set).id]
      end
    end
  end
end
