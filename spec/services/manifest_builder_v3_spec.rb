# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilderV3 do
  with_queue_adapter :inline
  subject(:manifest_builder) { described_class.new(query_service.find_by(id: resource.id)) }

  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }

  def logical_structure(file_set_id)
    [
      {
        "label": "Table of Contents",
        "nodes": [
          {
            "label": "Chapter 1",
            "nodes": [
              {
                "label": "Chapter 1a",
                "nodes": [
                  {
                    "proxy": file_set_id
                  }
                ]
              }
            ]
          }
        ]
      }.deep_symbolize_keys
    ]
  end

  describe "#build" do
    context "when given a scanned map" do
      let(:ocr_language) { "eng" }
      let(:title) { RDF::Literal.new("testin otsikko", language: :fin) }
      let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032).to_s }
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map,
                                         title: title,
                                         coverage: coverage,
                                         label: "test label",
                                         actor: "test person",
                                         sort_title: "test title2",
                                         rights_statement: RDF::URI("https://creativecommons.org/licenses/by-nc/4.0/"),
                                         call_number: "test value2",
                                         edition: "test edition",
                                         nav_date: "test date",
                                         identifier: "ark:/88435/abc1234de",
                                         source_metadata_identifier: "123456",
                                         imported_metadata: [{
                                           description: "Test Description",
                                           location: ["RCPPA BL980.G7 B66 1982"]
                                         }],
                                         viewing_direction: ["right-to-left"])
      end

      before do
        stub_catalog(bib_id: "123456")
        change_set = ScannedMapChangeSet.new(resource, files: [file])
        output = change_set_persister.save(change_set: change_set)
        change_set = ScannedMapChangeSet.new(output)
        file_set_id = change_set.member_ids.first
        change_set.validate(ocr_language: ocr_language)
        change_set.validate(logical_structure: logical_structure(file_set_id), start_canvas: file_set_id)
        change_set_persister.save(change_set: change_set)
      end

      it "builds a IIIF Presentation 3 document" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["summary"]["eng"]).to eq ["Test Description"]
        expect(output["items"].count { |i| i["type"] == "Canvas" }).to eq 1

        # RDF Literal title displays with correct language value
        title = output["metadata"].find { |m| m["label"]["eng"] == ["Title"] }
        expect(title["value"]["fin"]).to eq ["testin otsikko"]

        # structure
        expect(output["structures"][0]["items"][0]["label"]["eng"]).to eq ["Chapter 1"]

        # seeAlso
        expect(output["seeAlso"][0]["type"]).to eq "Dataset"

        # IIIFSearch
        expect(output["service"][0]["type"]).to eq "SearchService1"

        # rendering
        expect(output["rendering"][0]["format"]).to eq "application/pdf"

        # thumbnail
        expect(output["thumbnail"][0]["type"]).to eq "Image"

        # navPlace
        expect(output["navPlace"]["type"]).to eq "FeatureCollection"
      end
    end

    context "when a scanned map has imported coverage and is not downloadable" do
      let(:coverage) { GeoCoverage.new(43.039, -69.856, 42.943, -71.032).to_s }
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map,
                                         downloadable: "none",
                                         imported_metadata: [{
                                           coverage: coverage,
                                           description: "Test Description"
                                         }])
      end

      it "displays coverage and disables download" do
        output = manifest_builder.build

        # navPlace
        expect(output["navPlace"]["type"]).to eq "FeatureCollection"

        # not downloadable
        output["service"][0]["disableUI"] == ["mediaDownload"]
      end
    end

    context "when given a nested scanned map set" do
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id)
      end
      let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }
      it "builds a IIIF document" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["summary"]["eng"]).to eq ["Test Description"]
        expect(output["type"]).to eq "Manifest"
        expect(output["manifests"]).to be_nil
        expect(output["items"].count { |i| i["type"] == "Canvas" }).to eq 1

        # structure is empty when the resource has no stucture defined
        expect(output["structures"]).to be_nil
      end
    end

    context "when given a multi-volume map set" do
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: volume1.id)
      end
      let(:volume1) { FactoryBot.create_for_repository(:scanned_map, member_ids: child.id) }
      let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }

      it "builds a IIIF collection" do
        output = manifest_builder.build
        expect(output).to be_kind_of Hash
        expect(output["summary"]["eng"]).to eq ["Test Description"]
        expect(output["type"]).to eq "Collection"
        expect(output["manifests"].length).to eq 1
        expect(output["manifests"][0]["id"]).to eq "http://www.example.com/concern/scanned_maps/#{volume1.id}/manifest"
      end
    end

    context "when given a scanned map with a raster child" do
      let(:resource) do
        FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id)
      end
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }
      let(:child) { FactoryBot.create_for_repository(:raster_resource, files: [file]) }
      it "builds a IIIF document without the raster child" do
        output = manifest_builder.build
        expect(output["items"]).to be_empty
      end
    end
  end

  context "when in staging" do
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }
    it "generates pyramidal links" do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:test?).and_return(false)

      output = manifest_builder.build
      expect(output["items"][0]["items"][0]["items"][0]["body"]["id"]).to start_with "http://localhost:8182/pyramidals/iiif/2/"
    end
  end

  context "when the thumbnail derivative isn't generated" do
    with_queue_adapter :test
    let(:resource) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }

    before do
      allow(Rails.env).to receive(:development?).and_return(false)
      allow(Rails.env).to receive(:test?).and_return(false)
      reloaded_resource = query_service.find_by(id: resource.id)
      change_set = ScannedMapChangeSet.new(reloaded_resource, files: [file])
      output = change_set_persister.save(change_set: change_set)
      file_set_id = output.member_ids.first
      file_set = query_service.find_by(id: file_set_id)
      file_set.local_identifier = "p79409x97p"
      metadata_adapter.persister.save(resource: file_set)
      change_set = ScannedMapChangeSet.new(output)
      change_set.validate(logical_structure: logical_structure(file_set_id), start_canvas: file_set_id)
      change_set_persister.save(change_set: change_set)
    end
    it "doesn't error" do
      output = manifest_builder.build
      expect(output["thumbnail"]).to be_blank
    end
  end
end
