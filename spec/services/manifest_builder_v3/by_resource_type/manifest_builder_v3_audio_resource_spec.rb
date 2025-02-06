# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilderV3 do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_resource.id)) }

  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:schema_path) { Rails.root.join("spec", "fixtures", "iiif_v3_schema.json") }
  let(:schema) { JSON.parse(File.read(schema_path)) }
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

    it "builds a presentation 3 manifest", run_real_characterization: true do
      output = change_set_persister.save(change_set: change_set)
      output.logical_structure = [
        { label: "Logical", nodes: [{ proxy: output.member_ids.last }, { label: "Bla", nodes: [{ proxy: output.member_ids.first }] }] }
      ]

      change_set_persister.persister.save(resource: output)
      output = manifest_builder.build
      # pres 3 context is always an array
      expect(output["@context"]).to include "http://iiif.io/api/presentation/3/context.json"
      # logo is part of a provider object
      provider = output["provider"][0]
      expect(provider["type"]).to eq "Agent"
      expect(provider["logo"].first).to include("id" => "https://www.example.com/pul_logo_icon.png")
      # Logical structure should be able to have nested and un-nested members.
      expect(output["structures"][0]["items"][0]["id"]).to include "#t="
      expect(output["structures"][1]["items"][0]["items"][0]["id"]).to include "#t="
      expect(output["behavior"]).to eq ["auto-advance"]
      # downloading is blocked
      expect(output["items"][0].dig("rendering", 0, "format")).to be_nil
      # Use the Audio type
      expect(output["items"][0]["items"][0]["items"][0]["body"]["type"]).to eq "Sound"

      # Validate manifest
      expect(JSON::Validator.fully_validate(schema, output)).to be_empty
    end

    context "with an accompanying image file" do
      let(:image_file) { fixture_file_upload("files/example.tif") }
      let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file, image_file], downloadable: "none") }

      it "builds a manifest with an accompanyingCanvas element", run_real_characterization: true do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build

        expect(output["items"][0]["accompanyingCanvas"]["width"]).to eq 200

        # Validate manifest
        expect(JSON::Validator.fully_validate(schema, output)).to be_empty
      end
    end

    context "with multiple files" do
      let(:file2) { fixture_file_upload("av/la_c0652_2017_05_bag/data/32101047382401_2_pm.wav", "") }
      let(:file3) { fixture_file_upload("av/la_c0652_2017_05_bag2/data/32101047382492_1_i.wav", "") }
      let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file, file2, file3], downloadable: "none") }

      it "retrieves the parent resource only once", run_real_characterization: true do
        decorator = ScannedResourceDecorator.new(scanned_resource)
        allow_any_instance_of(ScannedResource).to receive(:decorate).and_return(decorator)
        allow(decorator).to receive(:downloadable?)
        change_set_persister.save(change_set: change_set)
        manifest_builder.build

        expect(decorator).to have_received(:downloadable?).once
      end
    end

    context "with no logical structure", run_real_characterization: true do
      let(:logical_structure) { nil }
      it "builds a presentation 3 manifest with a default table of contents" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build
        # A default table of contents should display
        expect(output["structures"][0]["items"][0]["id"]).to include "#t="
        expect(output["structures"][0]["label"]["eng"]).to eq ["32101047382401_1_pm.wav"]

        # Validate manifest
        expect(JSON::Validator.fully_validate(schema, output)).to be_empty
      end
    end

    context "when downloading is enabled" do
      let(:change_set) { ScannedResourceChangeSet.new(scanned_resource, files: [file], downloadable: "public") }
      it "doesn't block download" do
        change_set_persister.save(change_set: change_set)
        output = manifest_builder.build

        expect(output["service"]).to be_nil

        # Validate manifest
        expect(JSON::Validator.fully_validate(schema, output)).to be_empty
      end
    end
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

      expect(ranges.last["items"].length).to eq 1
      expect(ranges.last["items"].first).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }
      child_ranges = ranges.last["items"]
      expect(child_ranges.length).to eq 1
      expect(child_ranges.first).to include "items"
      range_canvases = child_ranges.first["items"]
      expect(range_canvases.length).to eq 1
      expect(range_canvases.first).to include "label" => { "eng" => ["32101047382401_1_pm.wav"] }

      # Validate manifest
      expect(JSON::Validator.fully_validate(schema, output)).to be_empty
    end
  end

  context "when given a recording ingested from an ArchivalMediaBag" do
    it "builds a manifest", run_real_characterization: true, run_real_derivatives: true do
      bag_path = Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag")
      user = User.first
      stub_findingaid(pulfa_id: "C0652")
      stub_findingaid(pulfa_id: "C0652_c0377")
      IngestArchivalMediaBagJob.perform_now(collection_component: "C0652", bag_path: bag_path, user: user, visibility: "open")

      recording = query_service.custom_queries.find_by_property(property: :local_identifier, value: "32101047382401").last
      # it can use the vatican logo
      recording.rights_statement = [RDF::URI("http://cicognara.org/microfiche_copyright")]
      manifest_builder = described_class.new(recording)
      output = manifest_builder.build
      expect(output).to include "items"
      canvases = output["items"]
      expect(canvases.length).to eq 2
      label = canvases.first["rendering"][0]["label"]
      expect(label["en"].first).to eq "Download the mp3"
      # This value rounds up/down based on mediainfo compilation, 0.255 vs 0.256
      # is close enough for our purpose
      expect(canvases.first["items"][0]["items"][0]["body"]["duration"].to_s).to start_with "0.25"
      logo = output["provider"][0]["logo"][0]
      expect(logo).to include("id" => "https://www.example.com/vatican.png",
                              "format" => "image/png",
                              "height" => 100,
                              "width" => 120,
                              "type" => "Image")

      # Validate manifest
      expect(JSON::Validator.fully_validate(schema, output)).to be_empty
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

      range_canvas = output["structures"][0]["items"][0]
      expect(range_canvas).to include "label" => { "eng" => ["32101047382401_1"] }
      expect(range_canvas).to include "items" => []
      expect(range_canvas).to include "duration" => 0.256

      # Validate manifest
      expect(JSON::Validator.fully_validate(schema, output)).to be_empty
    end
  end
end
