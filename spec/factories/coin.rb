# frozen_string_literal: true
FactoryBot.define do
  factory :coin, class: Numismatics::Coin do
    rights_statement RightsStatements.no_known_copyright
    read_groups "public"
    to_create do |instance|
      Valkyrie::MetadataAdapter.find(:indexing_persister).persister.save(resource: instance)
    end
    transient do
      files []
      user nil
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    after(:build) do |resource, evaluator|
      if evaluator.visibility.present?
        change_set = Numismatics::CoinChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        change_set = Numismatics::CoinChangeSet.new(resource, files: evaluator.files)
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end
    factory :open_coin do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    factory :private_coin do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    factory :campus_only_coin do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
    factory :complete_open_coin do
      state "complete"
    end
  end
end
