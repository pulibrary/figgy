# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_provenance, class: Numismatics::Provenance do
    date { "1/1/2023" }
    note { "provenance note" }

    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
