# frozen_string_literal: true
FactoryGirl.define do
  factory :collection do
    title 'Title'
    slug 'test'
    visibility 'open'
    read_groups 'public'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
