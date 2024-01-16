# frozen_string_literal: true
require "rails_helper"
require "open3"

RSpec.describe GeoDerivatives::Processors::Raster::Info do
  let(:processor) { described_class.new(path) }
  let(:path) { "test.tif" }
  let(:info_doc) { file_fixture("files/gdal/gdalinfo.json").read }
  let(:status) { double(success?: true) }

  before do
    allow(Open3).to receive(:capture3).and_return([info_doc, "", status])
  end

  context "after intialization" do
    describe "#driver" do
      it "returns the gdal driver" do
        expect(processor.driver).to eq("USGSDEM")
      end
    end

    describe "#size" do
      it "returns raster size" do
        expect(processor.size).to eq("310 266")
      end
    end

    describe "#bounds" do
      it "returns bounds hash" do
        expect(processor.bounds).to eq(north: 42.112773,
                                       east: -74.394294,
                                       south: 42.088625,
                                       west: -74.432005)
      end

      context "when a raster is located in the southern hemisphere" do
        let(:info_doc) { file_fixture("files/gdal/gdalinfo-southern.json").read }

        it "returns bounds hash" do
          expect(processor.bounds).to eq(north: -13.506975,
                                         east: -71.966924,
                                         south: -13.528812,
                                         west: -71.991192)
        end
      end
    end

    describe "#min_max" do
      let(:info_doc) { file_fixture("files/gdal/gdalinfo-aig.json").read }

      it "returns with min and max values" do
        expect(processor.min_max).to eq("2.054 11.717")
      end
    end

    context "when processor is run against a non-geo tiff" do
      let(:info_doc) { file_fixture("files/gdal/gdalinfo-no-geo-tiff.json").read }

      describe "#bounds" do
        it "returns an empty string" do
          expect(processor.bounds).to eq("")
        end
      end
    end
  end
end
