# frozen_string_literal: true
FactoryGirl.define do
  factory :ephemera_folder do
    barcode '12345678901234'
    folder_number 'one'
    title 'test folder'
    language 'test language'
    genre 'test genre'
    width '10'
    height '20'
    page_count '30'
    rights_statement RDF::URI('http://rightsstatements.org/vocab/NKC/1.0/')
    read_groups 'public'
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
        change_set = EphemeraFolderChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    factory :open_ephemera_folder do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    factory :private_ephemera_folder do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    factory :campus_only_ephemera_folder do
      visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end
end
