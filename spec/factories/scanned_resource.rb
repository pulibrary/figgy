# frozen_string_literal: true
FactoryGirl.define do
  factory :scanned_resource do
    title 'Title'
    rights_statement 'Test Statement'
    visibility 'open'
    read_groups 'public'
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
