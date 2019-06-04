# frozen_string_literal: true
FactoryBot.define do
  factory :numismatic_find, class: Numismatics::Find do
    place "Cyzicus"
    find_number 1
    feature "Kaoussie"
    locus "12-F"
    date "05/25/1935"
    description "Tomb in east end of room 4"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
