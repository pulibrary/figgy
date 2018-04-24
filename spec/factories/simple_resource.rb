# frozen_string_literal: true
FactoryBot.define do
  factory :simple_resource do
    title 'Title'
    rights_statement RDF::URI('http://rightsstatements.org/vocab/NKC/1.0/')
    read_groups 'public'
    pdf_type ['gray']
    state 'draft'
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
        change_set = SimpleResourceChangeSet.new(resource)
        change_set.validate(visibility: Array(evaluator.visibility).first)
        change_set.sync
        resource = change_set.model
      end
      resource
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        change_set = SimpleResourceChangeSet.new(resource, files: evaluator.files)
        change_set.prepopulate!
        ::PlumChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end
    factory :draft_simple_resource do
      state 'draft'
    end
    factory :published_simple_resource do
      state 'published'
    end
  end
end
