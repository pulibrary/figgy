# frozen_string_literal: true
require "rails_helper"

RSpec.describe ManifestBuilder do
  with_queue_adapter :inline
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  context "when given a scanned map" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map,
                                       description: "Test Description",
                                       references: { "http://www.jstor.org/stable/1797655": ["www.jstor.org"] }.to_json,
                                       electronic_locations: ["@id": "http://arks.princeton.edu/ark:/88435/1234567"])
    end
    let(:change_set) { ScannedMapChangeSet.new(scanned_map, files: [file]) }

    before do
      output = change_set_persister.save(change_set: change_set)
      change_set = ScannedMapChangeSet.new(output)
      change_set_persister.save(change_set: change_set)
    end

    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["sequences"][0]["canvases"][0]["images"].length).to eq 1
      expect(output["metadata"].find { |m| m["label"] == "Gbl Suppressed Override" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Rendered Coverage" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Electronic Locations" }).to be nil
      expect(output["metadata"].find { |m| m["label"] == "Rendered Links" }).to be nil
    end
  end

  context "when given a nested scanned map set" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id, start_canvas: child.id)
    end
    let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }
    it "builds a IIIF document" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["@type"]).to eq "sc:Manifest"
      expect(output["manifests"]).to eq nil
      expect(output["sequences"].first["canvases"].length).to eq 1
    end
  end

  context "when given a multi-volume map set" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: map_set.id)) }
    let(:map_set) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: volume1.id)
    end
    let(:volume1) { FactoryBot.create_for_repository(:scanned_map, member_ids: child.id) }
    let(:child) { FactoryBot.create_for_repository(:scanned_map, files: [file]) }

    it "builds a IIIF collection" do
      output = manifest_builder.build
      expect(output).to be_kind_of Hash
      expect(output["description"]).to eq ["Test Description"]
      expect(output["@type"]).to eq "sc:Collection"
      expect(output["viewingHint"]).to eq "multi-part"
      expect(output["manifests"].length).to eq 1
      expect(output["manifests"][0]["@id"]).to eq "http://www.example.com/concern/scanned_maps/#{volume1.id}/manifest"
      expect(output["manifests"][0]["viewingHint"]).to be_nil
      expect(output["manifests"][0]["metadata"]).to be_nil
    end
  end

  context "when given a scanned map with a raster child" do
    subject(:manifest_builder) { described_class.new(query_service.find_by(id: scanned_map.id)) }
    let(:scanned_map) do
      FactoryBot.create_for_repository(:scanned_map, description: "Test Description", member_ids: child.id)
    end

    before do
      allow(MosaicJob).to receive(:perform_later)
    end

    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff") }
    let(:child) { FactoryBot.create_for_repository(:raster_resource, files: [file]) }
    it "builds a IIIF document without the raster child" do
      output = manifest_builder.build
      expect(output["sequences"]).to be_nil
    end
  end

  context "when given a MapSet with Raster children" do
    it "adds rendering properties for the GeoTiff" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
      map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map.id])

      output = described_class.new(map_set).build

      uncropped_geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download GeoTiff"
      end

      cropped_geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download Cropped GeoTiff"
      end

      expect(uncropped_geo_rendering).to be_present
      expect(cropped_geo_rendering).to be_present
      uncropped_file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.blank? }
      cropped_file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.present? }
      expect(uncropped_geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{uncropped_file_set.id}/file/#{uncropped_file_set.original_file.id}"
      expect(cropped_geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{cropped_file_set.id}/file/#{cropped_file_set.original_file.id}"
    end
  end

  context "when given a ScannedMap with Raster child" do
    it "adds a rendering property for the GeoTiff" do
      scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_child)
      output = described_class.new(scanned_map).build

      geo_rendering = output["sequences"][0]["canvases"][0]["rendering"].find do |rendering|
        rendering["label"] == "Download GeoTiff"
      end

      expect(geo_rendering).to be_present
      file_set = scanned_map.decorate.decorated_raster_resources.first.members.find { |x| x.service_targets.blank? }
      expect(geo_rendering["@id"]).to eq "http://www.example.com/downloads/#{file_set.id}/file/#{file_set.original_file.id}"
    end
  end
end
