# frozen_string_literal: true

require "rails_helper"

describe Numismatics::MonogramWayfinder do
  subject(:numismatic_monogram_wayfinder) { described_class.new(resource: numismatic_monogram) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_monogram) { FactoryBot.create_for_repository(:numismatic_monogram) }

  let(:numismatic_monogram) do
    res = Numismatics::Monogram.new(title: "Alexander")
    ch = Numismatics::MonogramChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  describe "#monograms_count" do
    it "returns the number of all the monograms" do
      expect(numismatic_monogram_wayfinder.monograms_count).to eq 1
    end
  end
end
