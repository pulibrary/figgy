# frozen_string_literal: true

FactoryBot.define do
  factory :numismatic_person, class: Numismatics::Person do
    name1 "name1"
    name2 "name2"
    epithet "epithet"
    born "1868"
    died "1963"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
