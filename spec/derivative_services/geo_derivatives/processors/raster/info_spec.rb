# frozen_string_literal: true
require "rails_helper"
require "open3"

RSpec.describe GeoDerivatives::Processors::Raster::Info do
  let(:processor) { described_class.new(path) }
  let(:path) { "test.tif" }
  let(:info_doc) { file_fixture("files/gdal/gdalinfo.txt").read }

  context "when initializing a new info class" do
    before do
      allow(Open3).to receive(:capture3).and_return([info_doc, "", ""])
    end

    it "shells out to gdalinfo and sets the doc variable to the output string" do
      expect(processor.doc).to eq(info_doc)
      expect(Open3).to have_received(:capture3).with("gdalinfo -mm #{path}")
    end
  end

  context "after intialization" do
    before do
      allow(processor).to receive(:doc).and_return(info_doc)
    end

    describe "#driver" do
      it "returns the gdal driver" do
        expect(processor.driver).to eq("USGSDEM/USGS")
      end
    end

    describe "#min_max" do
      it "returns with min and max values" do
        expect(processor.min_max).to eq("354.000 900.000")
      end
    end

    describe "#size" do
      it "returns raster size" do
        expect(processor.size).to eq("310 266")
      end
    end

    describe "#bounds" do
      it "returns bounds hash" do
        expect(processor.bounds).to eq(north: 42.11273,
                                       east: 74.394897,
                                       south: 42.088583,
                                       west: 74.432166)
      end
    end

    context "when gdalinfo does not return data" do
      let(:info_doc) { file_fixture("files/gdal/gdalinfo-blank.txt").read }

      describe "#driver" do
        it "returns an empty string" do
          expect(processor.driver).to eq("")
        end
      end

      describe "#min_max" do
        it "returns an empty string" do
          expect(processor.min_max).to eq("")
        end
      end

      describe "#size" do
        it "returns an empty string" do
          expect(processor.size).to eq("")
        end
      end

      describe "#bounds" do
        it "returns an empty string" do
          expect(processor.bounds).to eq("")
        end
      end
    end

    context "when processor is run against a non-geo tiff" do
      let(:info_doc) { file_fixture("files/gdal/gdalinfo-no-geo-tiff.txt").read }

      describe "#bounds" do
        it "returns an empty string" do
          expect(processor.bounds).to eq("")
        end
      end
    end
  end
end
