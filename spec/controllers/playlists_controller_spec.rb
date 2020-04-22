# frozen_string_literal: true
require "rails_helper"

RSpec.describe PlaylistsController do
  let(:meta) { Valkyrie.config.metadata_adapter }
  let(:disk) { Valkyrie.config.storage_adapter }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: meta, storage_adapter: disk) }

  let(:file1) { fixture_file_upload("files/audio_file.wav") }
  let(:file2) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
  let(:recording) { FactoryBot.create_for_repository(:recording, files: [file1, file2]) }
  let(:file_set1) do
    recording.decorate.file_sets.first
  end
  let(:file_set2) do
    recording.decorate.file_sets.last
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
  let(:persisted) do
    change_set = PlaylistChangeSet.new(resource)
    change_set.validate(state: ["complete"])
    change_set_persister.save(change_set: change_set)
  end

  describe "#manifest", run_real_characterization: true do
    with_queue_adapter :inline

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
        expect(first_canvas["label"]["@none"]).to eq ["Proxy Title"]

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
        file_node1 = file_set1.file_metadata.select(&:derivative?).first
        expect(first_annotation["body"]).to include("id" => "http://www.example.com/downloads/#{file_set1.id}/file/#{file_node1.id}?auth_token=#{persisted.auth_token}")
      end
    end
  end
end
