# frozen_string_literal: true

require "rails_helper"

describe Numismatics::PersonWayfinder do
  subject(:numismatic_person_wayfinder) { described_class.new(resource: numismatic_person) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }

  let(:numismatic_person) do
    res = Numismatics::Person.new(title: "Alexander")
    ch = Numismatics::PersonChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  describe "#people_count" do
    it "returns the number of all the people" do
      expect(numismatic_person_wayfinder.people_count).to eq 1
    end
  end
end
