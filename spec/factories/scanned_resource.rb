# frozen_string_literal: true
FactoryBot.define do
  factory :scanned_resource do
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
      run_callbacks { false }
      append_id { nil }
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
      if evaluator.files.present? || evaluator.import_metadata || evaluator.run_callbacks || evaluator.append_id.present?
        import_metadata = "1" if evaluator.import_metadata
        change_set = ScannedResourceChangeSet.new(resource, files: evaluator.files, refresh_remote_metadata: import_metadata, append_id: evaluator.append_id)
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end

    factory :scanned_resource_with_video do
      files do
        [
          IngestableFile.new(
            file_path: Rails.root.join("spec", "fixtures", "files", "city.mp4"),
            mime_type: "video/mp4",
            original_filename: "city.mp4",
            use: Valkyrie::Vocab::PCDMUse.OriginalFile
          )
        ]
      end
    end

    factory :scanned_resource_with_video_and_captions do
      files do
        [
          IngestableFile.new(
            file_path: Rails.root.join("spec", "fixtures", "files", "city.mp4"),
            mime_type: "video/mp4",
            original_filename: "city.mp4",
            use: Valkyrie::Vocab::PCDMUse.OriginalFile,
            container_attributes: {
              files: [
                IngestableFile.new(
                  file_path: Rails.root.join("spec", "fixtures", "files", "caption.vtt"),
                  mime_type: "text/vtt",
                  original_filename: "caption.vtt",
                  use: Valkyrie::Vocab::PCDMUse.Caption,
                  node_attributes: {
                    caption_language: "eng"
                  }
                )
              ]
            }
          )
        ]
      end
    end

    factory :letter do
      change_set { "letter" }
      factory :draft_letter do
        state { "draft" }
      end
    end
    factory :simple_resource do
      change_set { "simple" }
      factory :draft_simple_resource do
        state { "draft" }
      end
    end
    factory :recording do
      change_set { "recording" }
      factory :draft_recording do
        state { "draft" }
      end
      factory :complete_recording do
        state { "complete" }
        downloadable { "none" }
        visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      end
      factory :recording_with_audio_file do
        after(:build) do |resource, _evaluator|
          resource.member_ids ||= []
          resource.member_ids += [FactoryBot.create_for_repository(:audio_file_set).id]
        end
      end
      factory :complete_recording_with_real_files do
        state { "complete" }
        files do
          [
            IngestableFile.new(
              file_path: Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_pm.wav"),
              mime_type: "audio/x-wav",
              original_filename: "32101047382401_1_pm.wav",
              use: Valkyrie::Vocab::PCDMUse.PreservationFile
            )
          ]
        end
        after(:create) do |resource, _evaluator|
          IngestIntermediateFileJob.perform_now(file_path: Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_i.wav").to_s,
                                                file_set_id: resource.member_ids.first.to_s)
        end
      end
    end

    factory :open_scanned_resource do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    factory :complete_open_scanned_resource do
      state { "complete" }
    end
    factory :complete_private_scanned_resource do
      state { "complete" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end
    factory :pending_private_scanned_resource do
      state { "pending" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end
    factory :takedown_scanned_resource do
      state { "takedown" }
    end
    factory :flagged_scanned_resource do
      state { "flagged" }
    end
    factory :pending_scanned_resource do
      state { "pending" }
    end
    factory :draft_cdl_resource do
      state { "draft" }
      change_set { "CDL::Resource" }
    end
    factory :complete_on_campus_scanned_resource do
      state { "complete" }
      visibility { ::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_ON_CAMPUS }
    end
    factory :complete_campus_only_scanned_resource do
      state { "complete" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
    factory :pending_campus_only_scanned_resource do
      state { "pending" }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
    factory :pending_reading_room_scanned_resource do
      state { "pending" }
      visibility { ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_READING_ROOM }
    end
    factory :reading_room_scanned_resource, aliases: [:complete_reading_room_scanned_resource] do
      state { "complete" }
      visibility { ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_READING_ROOM }
    end
    factory :pending_campus_ip_scanned_resource do
      state { "pending" }
      visibility { ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS }
    end
    factory :campus_ip_scanned_resource, aliases: [:complete_campus_ip_scanned_resource] do
      state { "complete" }
      visibility { ::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_ON_CAMPUS }
    end
    factory :metadata_review_scanned_resource do
      state { "metadata_review" }
    end
    factory :final_review_scanned_resource do
      state { "final_review" }
    end
    factory :complete_scanned_resource do
      state { "complete" }
      factory :complete_simple_resource do
        change_set { "simple" }
      end
    end
  end
end
