# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilderV3 do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: resource.id)) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }

  context "when it is a Playlist" do
    let(:resource) do
      FactoryBot.create_for_repository(:playlist)
    end
    let(:output) do
      manifest_builder.build
    end
    it "generates the Manifest" do
      expect(output).not_to be_empty
      expect(output).to include("label" => { "eng" => resource.title })
    end

    context "with proxies to FileSets", run_real_characterization: true do
      with_queue_adapter :inline

      let(:tika_output) { tika_wav_output }

      let(:file1) { fixture_file_upload("files/audio_file.wav") }
      let(:file2) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
      let(:file3) { fixture_file_upload("av/la_demo_bag/data/32101047382484_1_pm.wav") }
      let(:recording) { FactoryBot.create_for_repository(:recording, files: [file1, file2, file3]) }
      let(:file_set1) do
        recording.decorate.decorated_file_sets.first
      end
      let(:file_set2) do
        recording.decorate.decorated_file_sets.to_a[1]
      end
      let(:file_set3) do
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
      let(:proxy3) do
        res = ProxyFileSet.new(proxied_file_id: file_set3.id, label: "Proxy Title3")
        cs = ProxyFileSetChangeSet.new(res)
        change_set_persister.save(change_set: cs)
      end
      let(:resource) do
        FactoryBot.create_for_repository(
          :playlist,
          member_ids: [proxy1.id, proxy2.id, proxy3.id],
          logical_structure: [
            { label: "Test",
              nodes: [
                { label: "Chapter 1", nodes:
                  [
                    { proxy: proxy1.id },
                    { label: "Chapter 1a", nodes:
                      [
                        { proxy: proxy2.id }
                      ] },
                    {
                      proxy: proxy3.id
                    }
                  ] }
              ] }
          ]
        )
      end

      it "generates the Canvases for the FileSets" do
        expect(output).not_to be_empty

        expect(output).to include("rendering")
        expect(output["rendering"]).to be_empty

        expect(output).to include("items")
        expect(output["items"].length).to eq(3)

        first_canvas = output["items"].first
        expect(first_canvas["label"]["eng"]).to eq ["Proxy Title"]

        expect(first_canvas).to include("items")
        expect(first_canvas["items"].length).to eq(1)
        anno_page = first_canvas["items"].first
        expect(anno_page).to include("items")
        expect(anno_page["items"].length).to eq(1)
        first_annotation = anno_page["items"].first
        expect(first_annotation).to include("body")
        expect(first_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

        last_canvas = output["items"].last
        expect(last_canvas).to include("items")
        expect(last_canvas["items"].length).to eq(1)
        anno_page = last_canvas["items"].first
        expect(anno_page).to include("items")
        expect(anno_page["items"].length).to eq(1)
        last_annotation = anno_page["items"].first
        expect(last_annotation).to include("body")
        expect(last_annotation["body"]).to include("format" => "application/vnd.apple.mpegurl")

        expect(output["structures"][0]["items"][0]["label"]).to eq("eng" => ["Proxy Title"])
        expect(output["structures"][0]["items"][0]["items"][0]["id"].split("#").first).to eq first_canvas["id"]
        expect(output["structures"][0]["items"][1]["items"][0]["label"]).to eq("eng" => ["Proxy Title2"])
        expect(output["structures"][0]["items"][2]["label"]).to eq("eng" => ["Proxy Title3"])
      end

      context "when an authorization token is used to access the Playlist Manifest" do
        subject(:manifest_builder) { described_class.new(persisted, persisted.auth_token) }

        let(:persisted) do
          change_set = PlaylistChangeSet.new(resource)
          change_set.validate(state: ["complete"])
          change_set_persister.save(change_set: change_set)
        end

        it "generates links with the auth. token" do
          expect(output).not_to be_empty
          expect(output).to include("items")
          expect(output["items"].length).to eq(3)

          first_canvas = output["items"].first
          first_annotation_page = first_canvas["items"].first
          first_annotation = first_annotation_page["items"].first
          file_node1 = file_set1.file_metadata.find(&:derivative?)
          expect(first_annotation["body"]).to include("id" => "http://www.example.com/downloads/#{file_set1.id}/file/#{file_node1.id}/stream.m3u8?auth_token=#{persisted.auth_token}")
        end
      end

      context "when the derivative cannot be retrieved for the FileSet" do
        before do
          allow_any_instance_of(FileSet).to receive(:derivative_file).and_return(nil)
        end
        it "generates the Canvases for the FileSets" do
          expect(output).not_to be_empty

          first_canvas = output["items"].first
          first_annotation_page = first_canvas["items"].first
          first_annotation = first_annotation_page["items"].first
          expect(first_annotation["body"]["id"]).to be nil

          last_canvas = output["items"].last
          first_annotation_page = last_canvas["items"].first
          first_annotation = first_annotation_page["items"].first
          expect(first_annotation["body"]["id"]).to be nil
        end
      end

      context "when the recording has FileSets for the XML metadata file, an image file, and two audio files", run_real_derivatives: true do
        with_queue_adapter :inline
        subject(:manifest_builder) { described_class.new(recording) }

        let(:file1) { fixture_file_upload("files/audio_file.wav") }
        let(:file2) { fixture_file_upload("files/example.tif") }
        let(:recording) { FactoryBot.create_for_repository(:recording, files: [file1, file2]) }
        let(:file_set1) do
          recording.decorate.decorated_file_sets.first
        end
        let(:file_set2) do
          recording.decorate.decorated_file_sets.last
        end

        it "render the image as a background file" do
          manifest_builder
          output = manifest_builder.build

          expect(output).not_to be_empty
          expect(output).to include("items")
          items = output["items"]
          expect(items.length).to eq(1)

          audio_canvas = items.first
          pages = audio_canvas["items"]
          expect(pages.length).to eq(1)

          annotations = pages.first["items"]
          expect(annotations.length).to eq(1)

          body = annotations.last["body"]
          expect(body["label"]).to eq("eng" => ["audio_file.wav"])

          expect(output).to include("posterCanvas")
          poster_canvas = output["posterCanvas"]

          pages = poster_canvas["items"]
          expect(pages.length).to eq(1)

          annotations = pages.first["items"]
          expect(annotations.length).to eq(1)

          body = annotations.last["body"]
          expect(body["type"]).to eq("Image")
          expect(body["height"]).to eq(287)
          expect(body["width"]).to eq(200)
          expect(body["format"]).to eq("image/jpeg")
        end
      end
    end
  end
end
