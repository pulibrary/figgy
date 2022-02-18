# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaylistsFromRecording do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe ".playlists_from_recording" do
    it "returns all playlists that contain the given file set ids as proxies" do
      file_sets = Array.new(3) { FactoryBot.create_for_repository(:file_set) }
      proxy_file_set1 = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_sets[0].id)
      proxy_file_set2 = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_sets[2].id)
      recording_2_playlist = FactoryBot.create_for_repository(:playlist, member_ids: [proxy_file_set1.id, proxy_file_set2.id])
      recording_3_playlist = FactoryBot.create_for_repository(:playlist, member_ids: [proxy_file_set2.id])
      # No Playlists made from this recording.
      recording = FactoryBot.create_for_repository(:recording, member_ids: file_sets[1].id)
      # recording_2_playlist made from this recording.
      recording2 = FactoryBot.create_for_repository(:recording, member_ids: file_sets[0].id)
      # recording_2_playlist and recording_3_playlist made from this recording
      recording3 = FactoryBot.create_for_repository(:recording, member_ids: file_sets[2].id)

      expect(query.playlists_from_recording(recording: recording)).to eq []
      expect(query.playlists_from_recording(recording: recording2).map(&:id)).to eq [recording_2_playlist.id]
      expect(query.playlists_from_recording(recording: recording3).map(&:id)).to contain_exactly recording_2_playlist.id, recording_3_playlist.id
    end
  end
end
