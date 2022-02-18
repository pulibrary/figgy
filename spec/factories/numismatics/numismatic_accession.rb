# frozen_string_literal: true

FactoryBot.define do
  factory :numismatic_accession, class: Numismatics::Accession do
    accession_number 1
    date "01/01/2001"
    items_number 102
    type "gift"
    cost "$99.00"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
