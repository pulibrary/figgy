# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoveragePoint do
  describe "attributes" do
    let(:lat) { 40.34781552 }
    let(:lon) { -74.65862657 }
    it "lat and lon" do
      point = described_class.new(lat: lat, lon: lon)
      expect(point.lat).to eq lat
      expect(point.lon).to eq lon
    end
  end
end
