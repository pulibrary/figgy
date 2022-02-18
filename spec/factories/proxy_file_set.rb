# frozen_string_literal: true

FactoryBot.define do
  factory :proxy_file_set do
    sequence(:label) { |x| "File Set #{x}" }
    visibility Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
