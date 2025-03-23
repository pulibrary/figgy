# frozen_string_literal: true
FactoryBot.define do
  factory :ephemera_folder do
    barcode { "12345678901234" }
    local_identifier { "xyz1" }
    folder_number { "one" }
    title { "test folder" }
    language { "test language" }
    genre { "test genre" }
    width { "10" }
    height { "20" }
    page_count { "30" }
    alternative_title { "test alternative title" }
    series { "test series" }
    subject { "test subject" }
    creator { "test creator" }
    contributor { ["test contributor"] }
    publisher { ["test publisher"] }
    description { "test description" }
    date_created { "1970/01/01" }
    provenance { ["Donated by the Mario Bros."] }
    source_url { "http://example.com" }
    dspace_url { "http://example.com" }
    rights_statement { RightsStatements.no_known_copyright }
    read_groups { "public" }
    state { "needs_qa" }
    member_of_collection_ids { [] }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files { [] }
      user { nil }
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    after(:build) do |resource, evaluator|
      resource.depositor = evaluator.user.uid if evaluator.user.present?
      if evaluator.visibility.present?
        change_set = EphemeraFolderChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        change_set = EphemeraFolderChangeSet.new(resource, files: evaluator.files)
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      else
        resource
      end
    end
    factory :open_ephemera_folder do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
    end
    factory :private_ephemera_folder do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
    end
    factory :campus_only_ephemera_folder do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
    end
    factory :complete_ephemera_folder do
      state { "complete" }
    end
    factory :needs_qa_ephemera_folder do
      visibility { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      state { "needs_qa" }
    end
    factory :non_validating_ephemera_folder do
      barcode { nil }
    end
  end
end
