# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }

  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:scanned_resource) do
    FactoryBot.create_for_repository(
      :scanned_resource,
      title: "test title1",
      label: "test label",
      actor: "test person",
      sort_title: "test title2",
      portion_note: "test value1",
      rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
      call_number: "test value2",
      edition: "test edition",
      nav_date: "test date",
      identifier: "ark:/88435/abc1234de",
      source_metadata_identifier: "991234563506421",
      imported_metadata: [{
        description: "Test Description",
        location: ["RCPPA BL980.G7 B66 1982"]
      }],
      viewing_direction: ["right-to-left"]
    )
  end

  context "when given a scanned resource with audio files" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }
    let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "none") }
    let(:file) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
    let(:logical_structure) { nil }
    before do
      stub_catalog(bib_id: "991234563506421")
    end
    context "when downloading is enabled" do
      let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "public") }
      it "doesn't block download" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build

        expect(output["service"]).to be_nil
      end
    end

    it "builds a manifest for an ArchivalMediaBag ingested Recording", run_real_characterization: true, run_real_derivatives: true do
      bag_path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag")
      user = User.first
      stub_findingaid(pulfa_id: "C0652")
      stub_findingaid(pulfa_id: "C0652_c0377")
      IngestArchivalMediaBagJob.perform_now(collection_component: "C0652", bag_path: bag_path, user: user)

      recording = query_service.custom_queries.find_by_property(property: :local_identifier, value: "32101047382401").last
      # it can use the vatican logo
      recording.rights_statement = [RDF::URI("http://cicognara.org/microfiche_copyright")]
      manifest_builder = described_class.new(recording)
      output = manifest_builder.build
      expect(output).to include "items"
      canvases = output["items"]
      expect(canvases.length).to eq 2
      expect(canvases.first["rendering"].map { |h| h["label"] }).to contain_exactly "Download the mp3"
      # This value rounds up/down based on mediainfo compilation, 0.255 vs 0.256
      # is close enough for our purpose
      expect(canvases.first["items"][0]["items"][0]["body"]["duration"].to_s).to start_with "0.25"
      expect(output["logo"].first).to include("id" => "https://www.example.com/assets/vatican-2a0de5479c7ad0fcacf8e0bf4eccab9f963a5cfc3e0197051314c8d50969a478.png",
                                              "format" => "image/png",
                                              "height" => 100,
                                              "width" => 120,
                                              "type" => "Image")
    end

    context "when given a multi-volume recording", run_real_characterization: true, run_real_derivatives: true do
      subject(:manifest_builder) { described_class.new(scanned_resource) }

      let(:file1) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:file2) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:volume1) { FactoryBot.create_for_repository(:scanned_resource, files: [file1]) }
      let(:volume2) { FactoryBot.create_for_repository(:scanned_resource, files: [file2]) }
      let(:scanned_resource) do
        sr = FactoryBot.create_for_repository(:recording)
        cs = ScannedResourceChangeSet.new(sr)
        cs.validate(member_ids: [volume1.id, volume2.id])
        change_set_persister.save(change_set: cs)
      end
      let(:output) { manifest_builder.build }

      it "generates the Ranges for the audio FileSets" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2

        first_canvas = output["items"].first
        expect(first_canvas).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }

        last_canvas = output["items"].last
        expect(last_canvas).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }

        expect(output).to include "structures"
        ranges = output["structures"]
        expect(ranges.length).to eq 2

        expect(ranges.first["items"].length).to eq 1
        expect(ranges.first["items"].first).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }
        child_ranges = ranges.first["items"]
        expect(child_ranges.length).to eq 1
        expect(child_ranges.first).to include "items"
        range_canvases = child_ranges.first["items"]
        expect(range_canvases.length).to eq 1
        expect(range_canvases.first).to include "label" => [{ "eng" => ["32101047382401_1_pm.wav"] }]

        expect(ranges.last["items"].length).to eq 1
        expect(ranges.last["items"].first).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }
        child_ranges = ranges.last["items"]
        expect(child_ranges.length).to eq 1
        expect(child_ranges.first).to include "items"
        range_canvases = child_ranges.first["items"]
        expect(range_canvases.length).to eq 1
        expect(range_canvases.first).to include "label" => [{ "eng" => ["32101047382401_1_pm.wav"] }]
      end
    end

    context "when given a multi-volume recording with thumbnails", run_real_characterization: true, run_real_derivatives: true do
      subject(:manifest_builder) { described_class.new(scanned_resource) }

      let(:audio_file1) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:image_file1) { fixture_file_upload("files/example.tif") }
      let(:audio_file2) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_1_pm.wav", "") }
      let(:image_file2) { fixture_file_upload("files/example.tif") }
      let(:volume1) { FactoryBot.create_for_repository(:scanned_resource, files: [audio_file1, image_file1]) }
      let(:volume2) { FactoryBot.create_for_repository(:scanned_resource, files: [audio_file2, image_file2]) }
      let(:scanned_resource) do
        sr = FactoryBot.create_for_repository(:recording)
        cs = ScannedResourceChangeSet.new(sr)
        cs.validate(member_ids: [volume1.id, volume2.id])
        change_set_persister.save(change_set: cs)
      end
      let(:output) { manifest_builder.build }

      it "generates the posterCanvas for the Manifest" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2
        first_item = output["items"].first
        expect(first_item).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }

        expect(output).to include("posterCanvas")
        poster_canvas = output["posterCanvas"]
        pages = poster_canvas["items"]
        expect(pages.length).to eq(1)
        annotations = pages.first["items"]
        expect(annotations.length).to eq(1)
        body = annotations.last["body"]
        expect(body["type"]).to eq("Image")
      end
    end

    context "when given an ArchivalMediaCollection", run_real_characterization: true, run_real_derivatives: true do
      let(:collection) { FactoryBot.create_for_repository(:archival_media_collection) }
      let(:collection_members) { collection.decorate.members }
      let(:recording) { collection_members.first.decorate.members.first }
      let(:manifest_builder) { described_class.new(collection) }
      let(:output) { manifest_builder.build }

      before do
        bag_path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag")
        user = User.first
        stub_findingaid(pulfa_id: "C0652")
        stub_findingaid(pulfa_id: "C0652_c0377")
        IngestArchivalMediaBagJob.perform_now(collection_component: "C0652", bag_path: bag_path, user: user, member_of_collection_ids: [collection.id.to_s])
      end

      it "builds a presentation 3 manifest with recordings as separate canvases" do
        expect(output).to be_kind_of Hash
        expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
        expect(output["type"]).to eq "Manifest"
        expect(output["items"].length).to eq 2
        expect(output["items"].first).to include "label" => { "eng" => ["32101047382401_1"] }
        expect(output["items"].last).to include "label" => { "eng" => ["32101047382401_2"] }

        expect(output["structures"].length).to eq 2
        expect(output["structures"].first).to include "label" => { "eng" => ["32101047382401_1"] }
        expect(output["structures"].last).to include "label" => { "eng" => ["32101047382401_2"] }
      end
    end

    it "builds a presentation 3 manifest", run_real_characterization: true do
      output = change_set_persister.save(change_set: change_set)
      output.logical_structure = [
        { label: "Logical", nodes: [{ proxy: output.member_ids.last }, { label: "Bla", nodes: [{ proxy: output.member_ids.first }] }] }
      ]

      change_set_persister.persister.save(resource: output)
      output = manifest_builder.build
      # pres 3 context is always an array
      expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
      # logo is always an array
      expect(output["logo"].first).to include("id" => "https://www.example.com/assets/pul_logo_icon-5333765252f2b86e34cd7c096c97e79495fe4656c5f787c5510a84ee6b67afd8.png")
      # Logical structure should be able to have nested and un-nested members.
      expect(output["structures"][0]["items"][0]["id"]).to include "#t="
      expect(output["structures"][1]["items"][0]["items"][0]["id"]).to include "#t="
      expect(output["behavior"]).to eq ["auto-advance"]
      # downloading is blocked
      expect(output["service"][0]).to eq({ "@context" => "http://universalviewer.io/context.json", "profile" => "http://universalviewer.io/ui-extensions-profile", "disableUI" => ["mediaDownload"] })
    end
    context "with no logical structure", run_real_characterization: true do
      let(:logical_structure) { nil }
      it "builds a presentation 3 manifest with a default table of contents" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build
        # A default table of contents should display
        expect(output["structures"][0]["items"][0]["id"]).to include "#t="
        expect(output["structures"][0]["label"]["eng"]).to eq ["32101047382401_1_pm.wav"]
      end
    end
  end
end
