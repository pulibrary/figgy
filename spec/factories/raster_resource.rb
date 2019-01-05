# frozen_string_literal: true
FactoryBot.define do
  factory :raster_resource do
    title "Title"
    rights_statement RightsStatements.no_known_copyright
    read_groups "public"
    pdf_type ["gray"]
    state "pending"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files []
      user nil
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      import_metadata false
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
      if evaluator.visibility.present?
        change_set = RasterResourceChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present? || evaluator.import_metadata
        import_metadata = "1" if evaluator.import_metadata
        change_set = RasterResourceChangeSet.new(resource, files: evaluator.files, refresh_remote_metadata: import_metadata)
        change_set.prepopulate!
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end
    factory :open_raster_resource do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    factory :complete_open_raster_resource do
      state "complete"
    end
    factory :complete_private_raster_resource do
      state "complete"
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    factory :takedown_raster_resource do
      state "takedown"
    end
    factory :flagged_raster_resource do
      state "flagged"
    end
    factory :pending_raster_resource do
      state "pending"
    end
    factory :complete_campus_only_raster_resource do
      state "complete"
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
    factory :metadata_review_raster_resource do
      state "metadata_review"
    end
    factory :final_review_raster_resource do
      state "final_review"
    end
    factory :complete_raster_resource do
      state "complete"
    end
  end
end
