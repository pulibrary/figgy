# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe GeoserverMessageGenerator do
  with_queue_adapter :inline

  subject(:generator) { described_class.new(resource: file_set) }
  let(:resource_title) { "Test Title" }
  let(:file_set) { query_service.find_members(resource: resource).to_a.first }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:event_generator) { instance_double(EventGenerator, derivatives_created: true) }
  let(:geoserver_derivatives_path) { Figgy.config["geoserver"]["derivatives_path"] }

  before do
    allow(EventGenerator).to receive(:new).and_return(event_generator)
  end

  describe "#generate" do
    context "with a public vector resource derivative" do
      let(:file) { fixture_file_upload("files/vector/shapefile.zip", "application/zip") }
      let(:tika_output) { tika_shapefile_output }
      let(:resource) do
        FactoryBot.create_for_repository(
          :vector_resource,
          files: [file],
          title: RDF::Literal.new(resource_title, language: :en),
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        )
      end
      let(:shapefile_name) { "display_vector/#{file_set.id}.shp" }

      it "returns a valid message hash" do
        output = generator.generate
        expect(output["id"]).to eq(file_set.id.to_s)
        expect(output["layer_type"]).to eq(:shapefile)
        expect(output["workspace"]).to eq(Figgy.config["geoserver"]["open"]["workspace"])
        expect(output["path"]).to include(shapefile_name, geoserver_derivatives_path)
        expect(output["title"]).to eq(resource_title)
      end
    end

    context "with a restricted raster resource derivative" do
      let(:file) { fixture_file_upload("files/raster/geotiff.tif", "image/tif") }
      let(:tika_output) { tika_geotiff_output }
      let(:resource) do
        FactoryBot.create_for_repository(
          :raster_resource,
          files: [file],
          title: RDF::Literal.new(resource_title, language: :en),
          visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        )
      end
      let(:geo_tiff_name) { "display_raster.tif" }

      it "returns a valid message hash" do
        output = generator.generate
        expect(output["id"]).to eq(file_set.id.to_s)
        expect(output["layer_type"]).to eq(:geotiff)
        expect(output["workspace"]).to eq(Figgy.config["geoserver"]["authenticated"]["workspace"])
        expect(output["path"]).to include(geo_tiff_name, geoserver_derivatives_path)
        expect(output["title"]).to eq(resource_title)
      end
    end
  end
end
