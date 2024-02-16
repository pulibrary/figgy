# frozen_string_literal: true
require "rails_helper"

describe GeoDiscovery::DocumentBuilder::Wxs do
  with_queue_adapter :inline
  subject(:wxs_builder) { described_class.new(decorator) }

  let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wms_url: "", wfs_url: "", layer_name: "") }
  let(:decorator) { query_service.find_by(id: geo_work.id).decorate }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
  let(:change_set) { VectorResourceChangeSet.new(geo_work, files: [file]) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:query_service) { metadata_adapter.query_service }
  let(:file) { fixture_file_upload("files/vector/shapefile.zip", 'application/zip; ogr-format="ESRI Shapefile"') }
  let(:tika_output) { tika_shapefile_output }

  before do
    change_set_persister.save(change_set: change_set)
  end

  describe "#identifier" do
    context "public document" do
      it "returns a public identifier" do
        file_set_id = geo_work.member_ids[0]
        expect(wxs_builder.identifier).to eq "public-figgy:p-#{file_set_id}"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns the fileset id" do
        file_set_id = geo_work.member_ids[0]
        expect(wxs_builder.identifier).to eq file_set_id.to_s
      end
    end

    context "when the layer_name property is set on the resource" do
      let(:layer_name) { "layer" }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, layer_name: layer_name) }

      it "returns the overridden identifier" do
        expect(wxs_builder.identifier).to eq layer_name
      end
    end

    context "when the layer_name property is set to an empty array" do
      before do
        allow(decorator).to receive(:layer_name).and_return([""])
      end

      it "returns a public identifier if layer_name is set to empty array" do
        file_set_id = geo_work.member_ids[0]
        expect(wxs_builder.identifier).to eq "public-figgy:p-#{file_set_id}"
      end
    end
  end

  describe "#wms_path" do
    context "public document" do
      it "returns a public wms path" do
        expect(wxs_builder.wms_path).to eq "http://localhost:8080/geoserver/public-figgy/wms"
      end
    end

    context "restricted document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns a restricted value" do
        expect(wxs_builder.wms_path).to eq "http://localhost:8080/geoserver/restricted-figgy/wms"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.wms_path).to be_nil
      end
    end

    context "when the wms_url property is set on the resource" do
      let(:wms_url) { ["https://geoserver.princeton.edu/geoserver/mosaics/wms"] }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wms_url: wms_url) }

      it "returns a the overriden wms value" do
        expect(wxs_builder.wms_path).to eq wms_url.first
      end
    end

    context "when the wms_url property is set to an empty string" do
      let(:wms_url) { [""] }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wms_url: wms_url) }

      it "does not return the overriden wms value" do
        expect(wxs_builder.wms_path).not_to eq wms_url
      end
    end
  end

  describe "#wfs_path" do
    context "public document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns a valid wfs path" do
        expect(wxs_builder.wfs_path).to eq "http://localhost:8080/geoserver/public-figgy/wfs"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.wfs_path).to be_nil
      end
    end

    context "when the wfs_url property is set on the resource" do
      let(:wfs_url) { "https://geoserver.princeton.edu/geoserver/mosaics/wfs" }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wfs_url: wfs_url) }

      it "returns a the overriden wfs value" do
        expect(wxs_builder.wfs_path).to eq wfs_url
      end
    end

    context "when the wfs_url property is set to an empty string" do
      let(:wfs_url) { [""] }
      let(:geo_work) { FactoryBot.create_for_repository(:vector_resource, visibility: visibility, wfs_url: wfs_url) }

      it "does not return the overriden wfs value" do
        expect(wxs_builder.wfs_path).not_to eq wfs_url
      end
    end
  end

  describe "#pmtiles_path" do
    context "with a public document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns a public pmtiles path" do
        expect(wxs_builder.pmtiles_path).to include "http://localhost:8080/geodata-open"
      end
    end

    context "campus only document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns a restricted pmtiles path" do
        expect(wxs_builder.pmtiles_path).to include "http://localhost:8080/geodata-restricted"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.pmtiles_path).to be_nil
      end
    end
  end

  describe "#cog_path" do
    let(:geo_work) { FactoryBot.create_for_repository(:raster_resource, visibility: visibility) }
    let(:change_set) { RasterResourceChangeSet.new(geo_work, files: [file]) }
    let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tiff; gdal-format=GTiff") }
    let(:tika_output) { tika_geotiff_output }

    context "with a public document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
      it "returns a public cog path" do
        expect(wxs_builder.cog_path).to include "http://localhost:8080/geodata-open"
      end
    end

    context "campus only document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
      it "returns a restricted cog path" do
        expect(wxs_builder.cog_path).to include "http://localhost:8080/geodata-restricted"
      end
    end

    context "private document" do
      let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      it "returns a nil value" do
        expect(wxs_builder.cog_path).to be_nil
      end
    end
  end
end
