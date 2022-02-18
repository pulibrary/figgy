# frozen_string_literal: true

require "rails_helper"

describe Numismatics::PlaceWayfinder do
  subject(:numismatic_place_wayfinder) { described_class.new(resource: numismatic_place) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_place) { FactoryBot.create_for_repository(:numismatic_place) }

  let(:numismatic_place) do
    res1 = Numismatics::Place.new(title: "Polis1")
    res2 = Numismatics::Place.new(title: "Polis2")
    ch1 = Numismatics::PlaceChangeSet.new(res1)
    ch2 = Numismatics::PlaceChangeSet.new(res2)
    change_set_persister.save(change_set: ch1)
    change_set_persister.save(change_set: ch2)
  end

  describe "#places_count" do
    it "returns the number of all the places" do
      expect(numismatic_place_wayfinder.places_count).to eq 2
    end
  end
end
