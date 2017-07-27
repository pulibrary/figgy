# frozen_string_literal: true
FactoryGirl.define do
  factory :file_set do
    sequence(:title) { |x| "File Set #{x}" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
