# frozen_string_literal: true

require "rails_helper"
require "ruby-progressbar/outputs/null"

RSpec.describe RecordingDownloadableMigrator do
  let(:progress_bar) { ProgressBar.create(output: ProgressBar::Outputs::Null) }

  before do
    allow(ProgressBar).to receive(:create).and_return(progress_bar)
  end

  describe ".call" do
    it "changes downloadable to 'none' in all Recordings and Playlists" do
      recordings = Array.new(2) do
        FactoryBot.create_for_repository(:recording, downloadable: "public")
      end
      playlist = FactoryBot.create_for_repository(:playlist, downloadable: "public")
      sr = FactoryBot.create_for_repository(:scanned_resource, downloadable: "public")

      described_class.call

      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      recordings = query_service.find_many_by_ids(ids: recordings.map(&:id))
      expect(recordings.flat_map(&:downloadable)).to eq ["none", "none"]
      expect(query_service.find_by(id: sr.id).downloadable).to eq ["public"]
      expect(query_service.find_by(id: playlist.id).downloadable).to eq ["none"]
    end
  end
end
