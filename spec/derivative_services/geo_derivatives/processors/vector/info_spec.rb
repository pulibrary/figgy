# frozen_string_literal: true
require "rails_helper"
require "open3"

RSpec.describe GeoDerivatives::Processors::Vector::Info do
  let(:processor) { described_class.new(path) }
  let(:path) { "test.geojson" }
  let(:polygon_info_doc) { file_fixture("files/gdal/ogrinfo_polygon.json").read }
  let(:line_info_doc) { file_fixture("files/gdal/ogrinfo_line.json").read }
  let(:status) { double(success?: true) }

  before do
    allow(Open3).to receive(:capture3).and_return([polygon_info_doc, "", status])
  end

  context "when initializing a new info class" do
    it "shells out to ogrinfo and sets the doc variable to the output string" do
      expect(processor.doc).to eq(JSON.parse(polygon_info_doc))
      expect(Open3).to have_received(:capture3).with("ogrinfo", "-json", "-ro", "-so", "-al", path.to_s)
    end
  end

  context "with a polygon vector" do
    before do
      allow(Open3).to receive(:capture3).and_return([polygon_info_doc, "", status])
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
                                       east: -71.052852,
                                       south: 42.347654,
                                       west: -71.163867)
      end
    end
  end

  context "with a line vector" do
    before do
      allow(Open3).to receive(:capture3).and_return([line_info_doc, "", status])
    end

    describe "#geom" do
      it "returns vector geometry" do
        expect(processor.geom).to eq("Line")
      end
    end
  end

  context "when ogrinfo returns an error" do
    let(:status) { double(success?: false) }

    before do
      allow(Open3).to receive(:capture3).and_return([polygon_info_doc, "info error", status])
    end

    it "returns an empty doc" do
      expect(processor.doc).to eq({})
    end
  end
end
