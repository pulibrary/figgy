# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe PlaylistsController do
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
        label: ["Test Playlist"],
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
      let(:resource) { FactoryBot.create_for_repository(:recording, member_ids: audio_file.id) }
      let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

      it "creates a playlist with a media reserve file sets" do
        post :create, params: params
        expect(response).to be_redirect
        expect(response.location).to start_with "http://test.host/catalog/"
        id = response.location.split("/").last
        playlist = query_service.find_by(id: id)
        expect(playlist.label).to eq ["Playlist: #{resource.title.first}"]
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
      let(:extra_params) { { playlist: { label: ["My Playlist"] } } }
      it_behaves_like "an access controlled update request"

      context "when a Playlist has been created" do
        let(:resource) { FactoryBot.create_for_repository(:playlist) }
        let(:proxy_file_set) do
          proxy = ProxyFileSet.new
          cs = ProxyFileSetChangeSet.new(proxy)
          cs.prepopulate!
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
          cs.prepopulate!
          change_set_persister.save(change_set: cs)
        end
        let(:proxy_file_set2) do
          proxy = ProxyFileSet.new
          cs = ProxyFileSetChangeSet.new(proxy)
          cs.prepopulate!
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
    end
    describe "#manifest" do
      context "with a Playlist proxying to audio FileSets", run_real_characterization: true do
        with_queue_adapter :inline

        let(:tika_output) { tika_wav_output }

        let(:file1) { fixture_file_upload("files/audio_file.wav") }
        let(:file2) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
        let(:recording) { FactoryBot.create_for_repository(:scanned_resource, files: [file1, file2]) }
        let(:file_set1) do
          recording.decorate.file_sets.first
        end
        let(:file_set2) do
          recording.decorate.file_sets.last
        end
        let(:proxy1) do
          res = ProxyFileSet.new(proxied_file_id: file_set1.id)
          cs = ProxyFileSetChangeSet.new(res)
          cs.prepopulate!
          change_set_persister.save(change_set: cs)
        end
        let(:proxy2) do
          res = ProxyFileSet.new(proxied_file_id: file_set2.id)
          cs = ProxyFileSetChangeSet.new(res)
          cs.prepopulate!
          change_set_persister.save(change_set: cs)
        end
        let(:resource) do
          FactoryBot.create_for_repository(:playlist, member_ids: [proxy1.id, proxy2.id])
        end
        let(:user) { FactoryBot.create(:admin) }

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
          expect(first_annotation["body"]).to include("format" => "audio/mp3")

          last_canvas = manifest_values["items"].last
          expect(last_canvas).to include("items")
          expect(last_canvas["items"].length).to eq(1)
          anno_page = last_canvas["items"].first
          expect(anno_page).to include("items")
          expect(anno_page["items"].length).to eq(1)
          last_annotation = anno_page["items"].first
          expect(last_annotation).to include("body")
          expect(last_annotation["body"]).to include("format" => "audio/mp3")
        end
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
  end
end
