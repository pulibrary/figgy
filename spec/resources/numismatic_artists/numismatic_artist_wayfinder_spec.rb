# frozen_string_literal: true
require "rails_helper"

describe NumismaticArtistWayfinder do
  subject(:numismatic_artist_wayfinder) { described_class.new(resource: numismatic_artist) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_artist) do
    res = NumismaticArtist.new(title: "artist unknown")
    ch = NumismaticArtistChangeSet.new(res)
    ch.prepopulate!
    change_set_persister.save(change_set: ch)
  end
  let(:coin) do
    res = Coin.new(title: "hercules", weight: 5, numismatic_artist_ids: [numismatic_artist.id])
    ch = CoinChangeSet.new(res)
    ch.prepopulate!
    change_set_persister.save(change_set: ch)
  end

  before do
    coin
  end

  describe "#numismatic_artist_parent" do
    it "returns the parent coin for artist" do
      expect(numismatic_artist_wayfinder.numismatic_artist_parent).to eq coin
    end
  end
end
