# frozen_string_literal: true
FactoryGirl.define do
  factory :scanned_resource do
    title 'Title'
    rights_statement RDF::URI('http://rightsstatements.org/vocab/NKC/1.0/')
    read_groups 'public'
    pdf_type ["gray"]
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
        change_set = ScannedResourceChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        ::PlumChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: ScannedResourceChangeSet.new(resource, files: evaluator.files))
      end
    end
    factory :open_scanned_resource do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    factory :complete_open_scanned_resource do
      state "complete"
    end
    factory :complete_private_scanned_resource do
      state "complete"
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    factory :takedown_scanned_resource do
      state "takedown"
    end
    factory :flagged_scanned_resource do
      state "flagged"
    end
    factory :pending_scanned_resource do
      state "pending"
    end
    factory :complete_campus_only_scanned_resource do
      state "complete"
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
    factory :metadata_review_scanned_resource do
      state "metadata_review"
    end
    factory :final_review_scanned_resource do
      state "final_review"
    end
    factory :complete_scanned_resource do
      state "complete"
    end
  end
end
