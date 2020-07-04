# frozen_string_literal: true
require "rails_helper"

RSpec.describe DownloadsController do
  let(:meta) { Valkyrie.config.metadata_adapter }
  let(:disk) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: meta, storage_adapter: disk) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [sample_file]) }
  let(:file_set) { resource.member_ids.map { |id| meta.query_service.find_by(id: id) }.first }
  let(:file_node) { file_set.file_metadata.first }
  let(:user) { FactoryBot.create(:admin) }

  describe "GET /downloads/:obj/file/:id" do
    context "when logged in" do
      before do
        sign_in user if user
      end

      it "serves files that exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.body).to eq(sample_file.read)
        expect(response.content_length).to eq(196_882)
        expect(response.content_type).to eq("image/tiff")
        expect(response.headers["Content-Disposition"]).to eq('inline; filename="example.tif"')
      end

      it "returns an 404 when the file_set doesn't exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: "bogus" }
        expect(response.status).to eq(404)
      end

      it "returns an 404 when the file is not found on disk" do
        allow(disk).to receive(:find_by).and_raise(Valkyrie::StorageAdapter::FileNotFound)
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.status).to eq(404)
      end

      it "returns an appropriate error when the resource doesn't exist" do
        get :show, params: { resource_id: "bogus", id: "bogus" }
        expect(response.status).to eq(404)
      end
    end

    context "when not logged in and the parent is pending" do
      it "redirects to login" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end

    context "when not logged in and the parent is private" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, files: [sample_file]) }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end

      it "redirects to login" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end

    context "when not logged in and the parent is complete and open" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, files: [sample_file]) }

      before do
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
      end

      it "allows downloading the file" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.content_length).to eq(196_882)
        expect(response.content_type).to eq("image/tiff")
        expect(response.body).to eq(sample_file.read)
      end
    end

    context "with an auth token" do
      it "allows downloading the file" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s, auth_token: token.token }
        expect(response.content_length).to eq(196_882)
        expect(response.content_type).to eq("image/tiff")
        expect(response.body).to eq(sample_file.read)
      end
    end

    context "with a FileSet proxied as a member of a Playlist", run_real_characterization: true, run_real_derivatives: true do
      with_queue_adapter :inline
      let(:sample_file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
      let(:file_node) { file_set.file_metadata.find(&:derivative_partial?) }
      let(:playlist) do
        playlist = Playlist.new
        cs = PlaylistChangeSet.new(playlist)
        cs.validate(file_set_ids: [file_set.id], state: ["complete"])
        change_set_persister.save(change_set: cs)
      end

      it "allow clients to download the HLS partial file with an auth. token" do
        persisted_playlist = meta.query_service.find_by(id: playlist.id)

        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s, auth_token: persisted_playlist.auth_token }

        expect(response.content_length).to eq(5452)
        expect(response.content_type).to eq("video/MP2T")
      end
    end

    context "with an HLS playlist FileSet and an auth token" do
      it "modifies the playlist to include auth tokens" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        change_set_persister = ScannedResourcesController.change_set_persister
        file_set = FactoryBot.create_for_repository(:file_set)
        file = fixture_file_upload("files/hls_playlist.m3u8", "application/x-mpegURL")
        change_set = ChangeSet.for(file_set)
        change_set.files = [file]
        output = change_set_persister.save(change_set: change_set)

        get :show, params: { resource_id: output.id.to_s, id: output.file_metadata.first.id.to_s, auth_token: token.token }

        expect(response).to be_successful
        expect(M3u8::Playlist.read(response.body).items[0].segment).to end_with "?auth_token=#{token.token}"
      end
    end

    context "with a netID only complete HLS playlist part and no auth token" do
      let(:user) { FactoryBot.create(:campus_patron) }
      with_queue_adapter :inline
      it "allows download", run_real_derivatives: true, run_real_characterization: true do
        sign_in user
        file = fixture_file_upload("files/audio_file.wav", "audio/x-wav")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        parent = FactoryBot.create_for_repository(:complete_recording, files: [file], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        file_set = Wayfinder.for(parent).members.first
        partial = file_set.derivative_partial_files.first

        get :show, params: { resource_id: file_set.id.to_s, id: partial.id.to_s }

        expect(response).to be_successful
      end
      it "disallows download of the original file", run_real_derivatives: true, run_real_characterization: true do
        sign_in user
        file = fixture_file_upload("files/audio_file.wav", "audio/x-wav")
        stub_ezid(shoulder: "99999/fk4", blade: "123456")
        parent = FactoryBot.create_for_repository(:complete_recording, files: [file], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        file_set = Wayfinder.for(parent).members.first
        wav_file = file_set.original_files.first

        get :show, params: { resource_id: file_set.id.to_s, id: wav_file.id.to_s }

        expect(response).not_to be_successful
      end
    end

    context "with an HLS playlist FileSet and no auth token" do
      let(:user) { FactoryBot.create(:admin) }
      it "doesn't modify the playlist" do
        sign_in(user)
        change_set_persister = ScannedResourcesController.change_set_persister
        file_set = FactoryBot.create_for_repository(:file_set)
        file = fixture_file_upload("files/hls_playlist.m3u8", "application/x-mpegURL")
        change_set = ChangeSet.for(file_set)
        change_set.files = [file]
        output = change_set_persister.save(change_set: change_set)

        get :show, params: { resource_id: output.id.to_s, id: output.file_metadata.first.id.to_s }

        expect(response).to be_successful
        expect(M3u8::Playlist.read(response.body).items[0].segment).not_to include "?auth_token"
      end
    end

    context "with a FileSet proxied as member of multiple Playlists" do
      let(:sample_file) { fixture_file_upload("files/audio_file.wav", "audio/x-wav") }
      let(:playlist) do
        playlist = Playlist.new
        cs = PlaylistChangeSet.new(playlist)
        cs.validate(file_set_ids: [file_set.id], state: ["complete"])
        change_set_persister.save(change_set: cs)
      end
      let(:playlist2) do
        playlist = Playlist.new
        cs = PlaylistChangeSet.new(playlist)
        cs.validate(file_set_ids: [file_set.id], state: ["complete"])
        change_set_persister.save(change_set: cs)
      end

      before do
        playlist
      end

      it "allow clients to download the file with an auth. token" do
        persisted_playlist = meta.query_service.find_by(id: playlist2.id)

        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s, auth_token: persisted_playlist.auth_token }

        expect(response.content_length).to eq(147_550)
        expect(response.content_type).to eq("audio/x-wav")
        expect(response.body).to eq(sample_file.read)
      end
    end
  end
end
