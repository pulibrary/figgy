# frozen_string_literal: true
require "rails_helper"

describe NumismaticCitationWayfinder do
  subject(:numismatic_citation_wayfinder) { described_class.new(resource: numismatic_citation) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_citation) do
    res = NumismaticCitation.new(title: "athens")
    ch = NumismaticCitationChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end
  let(:coin) do
    res = Coin.new(title: "hercules", weight: 5, numismatic_citation_ids: [numismatic_citation.id])
    ch = CoinChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  before do
    coin
  end

  describe "#numismatic_citation_parent" do
    it "returns the parent coin for citation" do
      expect(numismatic_citation_wayfinder.numismatic_citation_parent).to eq coin
    end
  end
end
