# frozen_string_literal: true

FactoryBot.define do
  factory :numismatic_monogram, class: Numismatics::Monogram do
    title "Test Monogram"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
    transient do
      files []
    end
    after(:create) do |resource, evaluator|
      if evaluator.files.present?
        change_set = Numismatics::MonogramChangeSet.new(resource, files: evaluator.files)
        ::ChangeSetPersister.new(
          metadata_adapter: Valkyrie::MetadataAdapter.find(:indexing_persister),
          storage_adapter: Valkyrie.config.storage_adapter
        ).save(change_set: change_set)
      end
    end
  end
end
