# frozen_string_literal: true
FactoryBot.define do
  factory :media_resource do
    title "Title"
    rights_statement RDF::URI("http://rightsstatements.org/vocab/NKC/1.0/")
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
        change_set = MediaResourceChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
<<<<<<< HEAD
    factory :complete_media_resource do
      state "complete"
=======
    factory :published_media_resource do
      state "published"
>>>>>>> d8616123... adds lux order manager to figgy
    end
    factory :media_resource_with_audio_file do
      after(:build) do |resource, _evaluator|
        resource.member_ids ||= []
        resource.member_ids += [FactoryBot.create_for_repository(:audio_file_set).id]
      end
    end
  end
end
