# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_reference, class: Numismatics::Reference do
    title { "Test Reference" }
    short_title { "short-title" }
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
