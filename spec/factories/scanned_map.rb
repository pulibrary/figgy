# frozen_string_literal: true
FactoryBot.define do
  factory :scanned_map do
    title { "Title" }
    rights_statement { RightsStatements.no_known_copyright }
    read_groups { "public" }
    pdf_type { ["gray"] }
    state { "pending" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files { [] }
      user { nil }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      import_metadata { false }
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
      if evaluator.visibility.present?
        change_set = ScannedMapChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present? || evaluator.import_metadata
        import_metadata = "1" if evaluator.import_metadata
        change_set = ScannedMapChangeSet.new(resource, files: evaluator.files, refresh_remote_metadata: import_metadata)
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end
    factory :open_scanned_map do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    factory :complete_open_scanned_map do
      state { "complete" }
    end
    factory :complete_private_scanned_map do
      state { "complete" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end
    factory :takedown_scanned_map do
      state { "takedown" }
    end
    factory :flagged_scanned_map do
      state { "flagged" }
    end
    factory :pending_scanned_map do
      state { "pending" }
    end
    factory :complete_campus_only_scanned_map do
      state { "complete" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
    factory :metadata_review_scanned_map do
      state { "metadata_review" }
    end
    factory :final_review_scanned_map do
      state { "final_review" }
    end
    factory :complete_scanned_map do
      state { "complete" }
    end

    factory :map_set do
      state { "complete" }
      after(:build) do |resource, _evaluator|
        resource.member_ids ||= []
        resource.member_ids += [
          FactoryBot.create_for_repository(:scanned_map).id,
          FactoryBot.create_for_repository(:scanned_map).id
        ]
      end
    end

    factory :scanned_map_with_raster_children do
      state { "complete" }
      after(:build) do |resource, _evaluator|
        # Cloud file - "clipped", service_targets: tiles
        raster_file_set1 = FactoryBot.create_for_repository(:geo_raster_cloud_file)
        # Unclipped, no service target.
        raster_file_set2 = FactoryBot.create_for_repository(:geo_raster_cloud_file, service_targets: nil)
        scanned_map_file_set = FactoryBot.create_for_repository(:geo_image_file_set)
        resource.member_ids ||= []
        resource.member_ids += [
          FactoryBot.create_for_repository(:raster_resource, member_ids: [raster_file_set1.id, raster_file_set2.id]).id,
          scanned_map_file_set.id
        ]
      end
    end
  end
end
