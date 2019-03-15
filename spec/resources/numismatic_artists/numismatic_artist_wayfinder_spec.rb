# frozen_string_literal: true
require "rails_helper"

describe NumismaticArtistWayfinder do
  subject(:numismatic_artist_wayfinder) { described_class.new(resource: numismatic_artist) }

  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:numismatic_artist) do
    res = NumismaticArtist.new(title: "artist unknown")
    ch = NumismaticArtistChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  let(:issue) do
    res = NumismaticIssue.new(title: "Issue", numismatic_artist_ids: [numismatic_artist.id])
    ch = NumismaticIssueChangeSet.new(res)
    change_set_persister.save(change_set: ch)
  end

  before do
    issue
  end

  describe "#numismatic_artist_parent" do
    it "returns the parent issue for artist" do
      expect(numismatic_artist_wayfinder.numismatic_artist_parent).to eq issue
    end
  end
end
