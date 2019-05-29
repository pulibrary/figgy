# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Place do
  subject(:numismatic_place) { described_class.new city: "city", geo_state: "state", region: "region" }

  it "has properties" do
    expect(numismatic_place.city).to eq("city")
    expect(numismatic_place.geo_state).to eq("state")
    expect(numismatic_place.region).to eq("region")
  end
end
