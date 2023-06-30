# frozen_string_literal: true
require "rails_helper"
require "open3"

RSpec.describe GeoDerivatives::Processors::Vector::Info do
  let(:processor) { described_class.new(path) }
  let(:path) { "test.tif" }
  let(:polygon_info_doc) { file_fixture("files/gdal/ogrinfo_polygon.txt").read }
  let(:line_info_doc) { file_fixture("files/gdal/ogrinfo_line.txt").read }

  context "when initializing a new info class" do
    before do
      allow(Open3).to receive(:capture3).and_return([polygon_info_doc, "", ""])
    end

    it "shells out to ogrinfo and sets the doc variable to the output string" do
      expect(processor.doc).to eq(polygon_info_doc)
      expect(Open3).to have_received(:capture3).with("ogrinfo", "-ro", "-so", "-al", path.to_s)
    end
  end

  context "with a polygon vector" do
    before do
      allow(processor).to receive(:doc).and_return(polygon_info_doc)
    end

    describe "#name" do
      it "returns with min and max values" do
        expect(processor.name).to eq("tufts-cambridgegrid100-04")
      end
    end

    describe "#driver" do
      it "returns with the ogr driver" do
        expect(processor.driver).to eq("ESRI Shapefile")
      end
    end

    describe "#geom" do
      it "returns vector geometry" do
        expect(processor.geom).to eq("Polygon")
      end
    end

    describe "#bounds" do
      it "returns bounds hash" do
        expect(processor.bounds).to eq(north: 42.408249,
                                       east: -71.052853,
                                       south: 42.347654,
                                       west: -71.163867)
      end
    end
  end

  context "with a line vector" do
    before do
      allow(processor).to receive(:doc).and_return(line_info_doc)
    end

    describe "#geom" do
      it "returns vector geometry" do
        expect(processor.geom).to eq("Line")
      end
    end
  end
end
