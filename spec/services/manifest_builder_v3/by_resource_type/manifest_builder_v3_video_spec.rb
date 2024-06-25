# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilderV3 do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }

  context "when given a scanned resource with video files" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
    let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "none") }
    let(:file) { fixture_file_upload("files/city.mp4", "") }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
    before do
      stub_catalog(bib_id: "991234563506421")
      change_set_persister.save(change_set: change_set)
    end

    context "and the scanned resource has VTT files" do
      let(:change_set) { ChangeSet.for(query_service.find_by(id: scanned_resource.id)) }
      let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions) }
      it "adds a rendering for the canvas to download the caption", run_real_characterization: true, run_real_derivatives: true do
        output = manifest_builder.build
        rendering = output["items"][0]["rendering"]
        vtt_rendering = rendering.find { |x| x["format"] == "text/vtt" }
        expect(vtt_rendering["label"]).to eq "Download Caption - English (Original)"
      end
    end

    it "builds a manifest for playing video back", run_real_characterization: true, run_real_derivatives: true do
      output = manifest_builder.build
      expect(output).to include "items"
      expect(output["seeAlso"]).to be_a Array
      canvases = output["items"]
      expect(canvases.length).to eq 1
      expect(canvases.first["items"][0]["items"][0]["body"]["duration"]).to eq 5.312
      expect(canvases.first["items"][0]["items"][0]["body"]["type"]).to eq "Video"
      expect(output["structures"][0]["items"][0]["id"]).to include "#t="
    end
  end
end
