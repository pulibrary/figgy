# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe "Playlist requests", type: :request do
  with_queue_adapter :inline

  let(:sample_file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_private_scanned_resource, files: [sample_file]) }
  let(:file_set) { scanned_resource.member_ids.first }
  let(:user) { FactoryBot.create(:admin) }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:playlist) do
    res = Playlist.new
    cs = PlaylistChangeSet.new(res)
    cs.prepopulate!
    cs.validate(label: ["my playlist"], file_set_ids: [file_set.id], state: "complete")
    change_set_persister.save(change_set: cs)
  end

  before do
    stub_ezid(shoulder: "99999/fk4", blade: "123456")
    playlist
    auth_token
  end

  context "when the client passes an authorization token" do
    let(:auth_token) { playlist.auth_token }

    it "is granted access to the catalog show view" do
      get "/catalog/#{playlist.id}?auth_token=#{auth_token}"

      expect(response.status).to eq 200
      expect(response.body).not_to be_empty
    end

    it "is granted access to the IIIF presentation manifest" do
      get "/concern/playlists/#{playlist.id}/manifest?auth_token=#{auth_token}"

      expect(response.status).to eq 200

      manifest_values = JSON.parse(response.body)

      expect(manifest_values).to include("type" => "Manifest")
      expect(manifest_values).to include("items")
      expect(manifest_values["items"]).not_to be_empty
      expect(manifest_values["items"].first).to include("label" => { "@none" => ["Interview: ERM / Jose Donoso (A2)"] })
    end
  end
end
