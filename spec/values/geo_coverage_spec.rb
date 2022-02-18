# frozen_string_literal: true

require "rails_helper"

describe GeoCoverage do
  subject(:geo_coverage) { described_class.new(43.039, -69.856, 42.943, -71.032) }
  let(:cov_string) do
    "northlimit=43.039; eastlimit=-69.856; southlimit=42.943; "\
                     "westlimit=-71.032; units=degrees; projection=EPSG:4326"
  end

  describe "#parse" do
    context "with a valid coverage string" do
      it "returns a coverage instance" do
        coverage = described_class.parse(cov_string)
        expect(coverage).to be_an_instance_of(described_class)
        expect(coverage.n).to eq("43.039")
        expect(coverage.e).to eq("-69.856")
        expect(coverage.s).to eq("42.943")
        expect(coverage.w).to eq("-71.032")
      end
    end

    context "with an invalid coverage string" do
      it "returns nil" do
        expect(described_class.parse("invalid")).to be_nil
      end
    end
  end

  describe "parse_coordinate" do
    it "parses a coordinate" do
      expect(described_class.parse_coordinate(cov_string, /northlimit=([.\d\-]+);/)).to eq 43.039
    end
  end

  describe "#to_s" do
    it "converts coordinates to a coverage string" do
      expect(geo_coverage.to_s).to eq cov_string
    end

    context "with coordinates containing exponential notation" do
      subject(:geo_coverage) { described_class.new(3.5e-05, -3.5e-05, 3.5e-05, -3.5e-05) }

      let(:cov_string) do
        "northlimit=0.000035; eastlimit=-0.000035; southlimit=0.000035; westlimit=-0.000035; units=degrees; projection=EPSG:4326"
      end

      it "converts the coordinates into standard form" do
        expect(geo_coverage.to_s).to eq cov_string
      end
    end
  end
end
