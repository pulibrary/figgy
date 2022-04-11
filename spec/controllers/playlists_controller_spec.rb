# frozen_string_literal: true
require "rails_helper"
include FixtureFileUpload

RSpec.describe PlaylistsController, type: :controller do
  with_queue_adapter :inline
  let(:user) { nil }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }

  before do
    sign_in user if user
  end

  describe "new" do
    it_behaves_like "an access controlled new request"
  end

  describe "create" do
    let(:valid_params) do
      {
        title: ["Test Playlist"],
        visibility: "restricted"
      }
    end
    let(:invalid_params) do
      {
        visibility: "restricted"
      }
    end

    context "access control" do
      let(:params) { valid_params }
      it_behaves_like "an access controlled create request"
    end

    context "it creates a playlist with the media reserve filesets" do
      let(:user) { FactoryBot.create(:admin) }
      let(:params) { { recording_id: resource.id } }
      let(:audio_file) { FactoryBot.create_for_repository(:file_set) }
      let(:resource) { FactoryBot.create_for_repository(:recording, member_ids: audio_file.id, part_of: "mustest") }
      let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

      it "creates a playlist with a media reserve file sets" do
        post :create, params: params
        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.split("/").last
        playlist = query_service.find_by(id: id)
        expect(playlist.title).to eq ["Playlist: #{resource.title.first}"]
        expect(playlist.part_of).to eq ["mustest"]
        members = query_service.find_members(resource: playlist)
        expect(members.first).to be_a ProxyFileSet
        expect(members.first.label).to eq audio_file.title
        expect(members.first.proxied_file_id).to eq audio_file.id
        expect(playlist.member_ids.length).to eq 1
      end
    end
  end

  describe "destroy" do
    context "access control" do
      let(:factory) { :playlist }
      it_behaves_like "an access controlled destroy request"
    end
  end

  describe "edit" do
    let(:user) { FactoryBot.create(:admin) }
    context "access control" do
      let(:factory) { :playlist }
      it_behaves_like "an access controlled edit request"
    end
  end

  describe "html update" do
    let(:user) { FactoryBot.create(:admin) }

    context "html access control" do
      let(:factory) { :playlist }
      let(:extra_params) { { playlist: { title: ["My Playlist"] } } }
      it_behaves_like "an access controlled update request"

      context "when a Playlist has been created" do
        let(:resource) { FactoryBot.create_for_repository(:playlist) }
        let(:proxy_file_set) do
          proxy = ProxyFileSet.new
          cs = ProxyFileSetChangeSet.new(proxy)
          change_set_persister.save(change_set: cs)
        end

        it "adds member IDs for proxies" do
          patch :update, params: { id: resource.id.to_s, playlist: { member_ids: [proxy_file_set.id] } }

          expect(response).to be_redirect
          expect(response.location).to eq "http://test.host/catalog/#{resource.id}"
          id = response.location.gsub("http://test.host/catalog/", "")
          reloaded = query_service.find_by(id: id)

          expect(reloaded.member_ids).to eq [proxy_file_set.id]
        end
      end

      context "when a Playlist has been linked to ProxyFileSets" do
        let(:proxy_file_set) do
          proxy = ProxyFileSet.new
          cs = ProxyFileSetChangeSet.new(proxy)
          change_set_persister.save(change_set: cs)
        end
        let(:proxy_file_set2) do
          proxy = ProxyFileSet.new
          cs = ProxyFileSetChangeSet.new(proxy)
          change_set_persister.save(change_set: cs)
        end
        let(:resource) { FactoryBot.create_for_repository(:playlist, member_ids: [proxy_file_set.id]) }

        it "replaces member IDs for proxies" do
          patch :update, params: { id: resource.id.to_s, playlist: { member_ids: [proxy_file_set2.id] } }

          expect(response).to be_redirect
          expect(response.location).to eq "http://test.host/catalog/#{resource.id}"
          id = response.location.gsub("http://test.host/catalog/", "")
          reloaded = query_service.find_by(id: id)

          expect(reloaded.member_ids).to eq [proxy_file_set2.id]
        end
      end

      context "when duplicate member FileSet IDs are passed" do
        let(:resource) { FactoryBot.create_for_repository(:playlist) }
        let(:file) { fixture_file_upload("files/audio_file.wav") }
        let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, files: [file]) }
        let(:file_set) { scanned_resource.decorate.members.first }
        it "filters the duplicate FileSet IDs" do
          expect(resource.member_ids).to be_empty
          patch :update, params: { id: resource.id.to_s, playlist: { file_set_ids: [file_set.id, file_set.id] } }

          reloaded = query_service.find_by(id: resource.id)
          expect(reloaded.member_ids.length).to eq(1)
          expect(reloaded.decorate.decorated_proxies.first.proxied_file_id).to eq(file_set.id)
        end
      end
    end

    describe "#manifest", run_real_characterization: true do
      with_queue_adapter :inline

      let(:tika_output) { tika_wav_output }

      let(:file1) { fixture_file_upload("files/audio_file.wav") }
      let(:file2) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
      let(:recording) { FactoryBot.create_for_repository(:scanned_resource, files: [file1, file2]) }
      let(:file_set1) do
        recording.decorate.decorated_file_sets.first
      end
      let(:file_set2) do
        recording.decorate.decorated_file_sets.last
      end
      let(:proxy1) do
        res = ProxyFileSet.new(proxied_file_id: file_set1.id, label: "Proxy Title")
        cs = ProxyFileSetChangeSet.new(res)
        change_set_persister.save(change_set: cs)
      end
      let(:proxy2) do
        res = ProxyFileSet.new(proxied_file_id: file_set2.id, label: "Proxy Title2")
        cs = ProxyFileSetChangeSet.new(res)
        change_set_persister.save(change_set: cs)
      end
      let(:resource) do
        FactoryBot.create_for_repository(:playlist, member_ids: [proxy1.id, proxy2.id])
      end
      let(:user) { FactoryBot.create(:admin) }

      context "with a Playlist proxying to audio FileSets" do
        it "generates the IIIF Manifest" do
          get :manifest, params: { id: resource.id, format: :json }

          expect(response.status).to eq(200)
          expect(response.body).not_to be_empty
          manifest_values = JSON.parse(response.body)

          expect(manifest_values).to include("items")
          expect(manifest_values["items"].length).to eq(2)

          first_canvas = manifest_values["items"].first

          expect(first_canvas).to include("items")
          expect(first_canvas["items"].length).to eq(1)
          anno_page = first_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          first_annotation = anno_page["items"].first
          expect(first_annotation).to include("body")
          expect(first_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

          last_canvas = manifest_values["items"].last
          expect(last_canvas).to include("items")
          expect(last_canvas["items"].length).to eq(1)
          anno_page = last_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          last_annotation = anno_page["items"].first
          expect(last_annotation).to include("body")
          expect(last_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")
        end
      end

      context "when an invalid resource ID is requested" do
        it "returns a not found status response" do
          get :manifest, params: { id: "invalid", format: :json }

          expect(response.status).to eq(200)
          expect(response.body).not_to be_empty
          response_message = JSON.parse(response.body)

          expect(response_message).to include("message" => "No manifest found for invalid")
        end
      end

      context "when authenticated" do
        let(:user) { FactoryBot.create(:admin) }

        before do
          sign_in user
        end

        it "generates the manifest for the resource" do
          get :manifest, params: { id: resource.id.to_s }, format: :json

          expect(response.body).not_to be_empty
          manifest_values = JSON.parse(response.body)
          expect(manifest_values).not_to be_empty

          expect(manifest_values).to include("items")
          expect(manifest_values["items"].length).to eq(2)

          first_canvas = manifest_values["items"].first
          expect(first_canvas["label"]["eng"]).to eq ["Proxy Title"]

          expect(first_canvas).to include("items")
          expect(first_canvas["items"].length).to eq(1)
          anno_page = first_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          first_annotation = anno_page["items"].first
          expect(first_annotation).to include("body")
          expect(first_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

          last_canvas = manifest_values["items"].last
          expect(last_canvas).to include("items")
          expect(last_canvas["items"].length).to eq(1)
          anno_page = last_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          last_annotation = anno_page["items"].first
          expect(last_annotation).to include("body")
          expect(last_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")
        end

        context "when transmitting a HEAD request" do
          it "responds with a link header specifying the title of the resource" do
            head :manifest, params: { id: resource.id.to_s }, format: :json

            expect(response).to be_successful
            expect(response.headers).to include "Link"
            expect(response.headers["Link"]).to eq "<http://test.host/concern/playlists/#{resource.id}/manifest>; rel=\"self\"; title=\"#{resource.title.first}\""
          end
        end
      end

      context "when the request contains an authorization token" do
        let(:persisted) do
          change_set = PlaylistChangeSet.new(resource)
          change_set.validate(state: ["complete"])
          change_set_persister.save(change_set: change_set)
        end

        it "generates a manifest with URLs containing the auth. token" do
          get :manifest, params: { id: persisted.id.to_s, auth_token: persisted.auth_token }, format: :json

          expect(response.body).not_to be_empty
          manifest_values = JSON.parse(response.body)

          expect(manifest_values).not_to be_empty
          expect(manifest_values).to include("items")
          expect(manifest_values["items"].length).to eq(2)

          first_canvas = manifest_values["items"].first
          first_annotation_page = first_canvas["items"].first
          first_annotation = first_annotation_page["items"].first
          file_node1 = file_set1.file_metadata.find(&:derivative?)
          expect(first_annotation["body"]).to include("id" => "http://www.example.com/downloads/#{file_set1.id}/file/#{file_node1.id}?auth_token=#{persisted.auth_token}")
        end
      end
    end
  end

  describe "structure" do
    let(:user) { FactoryBot.create(:admin) }

    context "when not logged in" do
      let(:user) { nil }
      it "redirects to login or root" do
        resource = FactoryBot.create_for_repository(:playlist)

        get :structure, params: { id: resource.id.to_s }
        expect(response).to be_redirect
      end
    end

    context "when a playlist doesn't exist" do
      it "raises an error" do
        get :structure, params: { id: "banana" }
        expect(response).to redirect_to_not_found
      end
    end

    context "when it does exist" do
      render_views
      it "renders a structure editor form" do
        file_set = FactoryBot.create_for_repository(:file_set)
        proxy_file_set = FactoryBot.create_for_repository(:proxy_file_set, proxied_file_id: file_set.id)
        resource = FactoryBot.create_for_repository(
          :playlist,
          member_ids: proxy_file_set.id,
          logical_structure: [
            { label: "testing", nodes: [{ label: "Chapter 1", nodes: [{ proxy: proxy_file_set.id }] }] }
          ]
        )

        query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
        allow(query_service).to receive(:find_by).with(id: resource.id).and_call_original
        allow(query_service).to receive(:find_inverse_references_by)
        get :structure, params: { id: resource.id.to_s }

        expect(response.body).to have_selector "li[data-proxy='#{proxy_file_set.id}']"
        expect(response.body).to have_field("label", with: "Chapter 1")
        expect(response.body).to have_link resource.title.first, href: solr_document_path(id: resource.id)
        expect(query_service).not_to have_received(:find_inverse_references_by)
      end
    end
  end
end
