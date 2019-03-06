# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_artist do
    person "artist person"
    signature "artist signature"
    role "artist role"
    side "artist side"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
