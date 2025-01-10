# frozen_string_literal: true
require "rails_helper"

RSpec.describe DownloadsController do
  let(:meta) { Valkyrie.config.metadata_adapter }
  let(:disk) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: meta, storage_adapter: disk) }
  let(:sample_file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:file_contents) { sample_file.read }
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, files: [sample_file]) }
  let(:file_set) { resource.member_ids.map { |id| meta.query_service.find_by(id: id) }.first }
  let(:file_node) { file_set.file_metadata.first }
  let(:user) { FactoryBot.create(:admin) }

  before do
    # Stash the contents in the let before the FileAppender closes the file
    # handle.
    file_contents
  end

  describe "GET /downloads/:obj/file/:id" do
    context "when logged in" do
      before do
        sign_in user if user
      end

      it "serves files that exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.body).to eq(file_contents)
        expect(response.content_length).to eq(196_882)
        expect(response.media_type).to eq("image/tiff")
        expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"example.tif\"; filename*=UTF-8''example.tif")
      end

      # The following appears to be from old items before we set this metadata.
      it "doesn't error if there's no updated_at on the file description" do
        file_set.file_metadata.first.updated_at = nil
        change_set_persister.metadata_adapter.persister.save(resource: file_set)

        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }

        expect(response.body).to eq(file_contents)
        expect(response.content_length).to eq(196_882)
        expect(response.media_type).to eq("image/tiff")
        expect(response.headers["Content-Disposition"]).to eq("inline; filename=\"example.tif\"; filename*=UTF-8''example.tif")
      end

      it "returns an 404 when the file_set doesn't exist" do
        get :show, params: { resource_id: file_set.id.to_s, id: "bogus" }
        expect(response.status).to eq(404)
      end

      it "returns an 404 when the file is not found on disk" do
        file_set
        file_node
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
        stub_ezid
      end

      it "redirects to login" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response).to redirect_to("/users/auth/cas")
      end
    end

    context "when not logged in and the parent is complete and open" do
      let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC, files: [sample_file]) }

      before do
        stub_ezid
      end

      it "allows downloading the file" do
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s }
        expect(response.content_length).to eq(196_882)
        expect(response.media_type).to eq("image/tiff")
        expect(response.body).to eq(file_contents)
      end
    end

    context "with an auth token" do
      it "allows downloading the file" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        get :show, params: { resource_id: file_set.id.to_s, id: file_node.id.to_s, auth_token: token.token }
        expect(response.content_length).to eq(196_882)
        expect(response.media_type).to eq("image/tiff")
        expect(response.body).to eq(file_contents)
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

        expect(response.content_length).to eq(9964)
        expect(response.media_type).to eq("video/MP2T")
      end
    end

    context "with a VTT file" do
      with_queue_adapter :inline
      it "can generate an HLS manifest for it", run_real_characterization: true do
        stub_ezid
        output = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions, state: "complete")
        file_set = Wayfinder.for(output).file_sets.first
        file_metadata = file_set.file_metadata.find(&:caption?)

        get :show, params: { resource_id: file_set.id.to_s, id: file_metadata.id.to_s, as: "stream", format: "m3u8" }

        expect(response).to be_successful
        playlist = M3u8::Playlist.read(response.body)
        expect(playlist.target).to eq 6
        expect(playlist.items.length).to eq 1
        expect(playlist.items[0].segment).to eq "/downloads/#{file_set.id}/file/#{file_metadata.id}"
      end
    end

    context "with an HLS playlist FileSet and ?as=stream" do
      context "with no auth token given" do
        with_queue_adapter :inline
        it "doesn't append one", run_real_derivatives: true, run_real_characterization: true do
          stub_ezid
          output = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions, state: "complete")
          file_set = Wayfinder.for(output).file_sets.first
          file_metadata = file_set.file_metadata.find(&:hls_manifest?)
          caption_metadata = file_set.captions.first

          get :show, params: { resource_id: file_set.id.to_s, id: file_metadata.id.to_s, as: "stream", format: "m3u8" }

          expect(response).to be_successful
          playlist = M3u8::Playlist.read(response.body)
          expect(playlist.items.length).to eq 3
          expect(playlist.items[0].uri).to eq "/downloads/#{file_set.id}/file/#{file_metadata.id}.m3u8"
          expect(playlist.items[0].subtitles).to eq "subs"
          expect(playlist.items[1].uri).to eq "/downloads/#{file_set.id}/file/#{caption_metadata.id}/stream.m3u8"
          expect(playlist.items[1].language).to eq "eng"
          expect(playlist.items[1].characteristics).to eq "public.accessibility.describes-spoken-dialog,public.accessibility.describes-music-and-sound"
          expect(playlist.items[1].name).to eq "English (Original)"
          expect(playlist.items[1].default).to be true
          expect(playlist.items[2].language).to eq "und"
          expect(playlist.items[2].characteristics).to eq "public.accessibility.describes-spoken-dialog,public.accessibility.describes-music-and-sound"
          expect(playlist.items[2].name).to eq "Undetermined"
          expect(playlist.items[2].default).to be false
        end
      end

      it "creates a primary playlist with the auth token" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        change_set_persister = ChangeSetPersister.default
        file_set = FactoryBot.create_for_repository(:file_set)
        file = fixture_file_upload("files/hls_playlist.m3u8", "application/x-mpegURL")
        change_set = ChangeSet.for(file_set)
        change_set.files = [file]
        output = change_set_persister.save(change_set: change_set)

        get :show, params: { resource_id: output.id.to_s, id: output.file_metadata.first.id.to_s, as: "stream", auth_token: token.token, format: "m3u8" }

        expect(response).to be_successful
        playlist = M3u8::Playlist.read(response.body)
        expect(playlist.items.length).to eq 1
        expect(playlist.items[0].uri).to eq "/downloads/#{output.id}/file/#{output.file_metadata.first.id}.m3u8?auth_token=#{token.token}"
      end
    end

    context "with an HLS playlist FileSet and an auth token" do
      it "modifies the playlist to include auth tokens" do
        token = AuthToken.create!(group: ["admin"], label: "admin_token")
        change_set_persister = ChangeSetPersister.default
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
        stub_ezid
        parent = FactoryBot.create_for_repository(:complete_recording, files: [file], visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED)
        file_set = Wayfinder.for(parent).members.first
        partial = file_set.derivative_partial_files.first

        get :show, params: { resource_id: file_set.id.to_s, id: partial.id.to_s }

        expect(response).to be_successful
      end

      it "disallows download of the original file", run_real_derivatives: true, run_real_characterization: true do
        sign_in user
        file = fixture_file_upload("files/audio_file.wav", "audio/x-wav")
        stub_ezid
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
        change_set_persister = ChangeSetPersister.default
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
        expect(response.media_type).to eq("audio/x-wav")
        expect(response.body).to eq(file_contents)
      end
    end

    context "with an FGDC metadata file" do
      with_queue_adapter :inline
      let(:parent_resource) do
        change_set_persister.save(change_set: VectorResourceChangeSet.new(VectorResource.new, files: [fgdc_file], member_ids: [vector_file_set.id]))
      end
      let(:fgdc_file) { fixture_file_upload("files/geo_metadata/fgdc-no-onlink.xml", "application/xml") }
      let(:fgdc_file_set) { Wayfinder.for(parent_resource).geo_metadata_members.first }
      let(:vector_file_set) { FactoryBot.create_for_repository(:file_set, file_metadata: vector_file_metadata) }
      let(:vector_file_id) { "1234567" }
      let(:vector_file_metadata) do
        FileMetadata.new(
          id: Valkyrie::ID.new(vector_file_id),
          use: [::PcdmUse::OriginalFile],
          mime_type: 'application/zip; ogr-format="ESRI Shapefile"'
        )
      end
      # Shared output context for stubbing tika
      let(:tika_output) { tika_xml_output }

      it "modifies inserts an onlink value into the file" do
        get :show, params: { resource_id: fgdc_file_set.id.to_s, id: fgdc_file_set.file_metadata.first.id.to_s }

        expect(response).to be_successful
        doc = Nokogiri::XML(response.body)
        expect(doc.at_xpath("//idinfo/citation/citeinfo/onlink").text).to match(/#{vector_file_set.id}\/file\/#{vector_file_id}/)
      end
    end
  end
end
