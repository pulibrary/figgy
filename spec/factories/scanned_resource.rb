# frozen_string_literal: true
FactoryGirl.define do
  factory :scanned_resource do
    title 'Title'
    rights_statement RDF::URI('http://rightsstatements.org/vocab/NKC/1.0/')
    visibility 'open'
    read_groups 'public'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files []
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        ::PlumChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: ScannedResourceChangeSet.new(resource, files: evaluator.files))
      end
    end
  end
end
