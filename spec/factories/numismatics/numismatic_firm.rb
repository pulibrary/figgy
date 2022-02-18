# frozen_string_literal: true

FactoryBot.define do
  factory :numismatic_firm, class: Numismatics::Firm do
    city "firm city"
    name "firm name"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
