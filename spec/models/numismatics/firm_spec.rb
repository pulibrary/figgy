# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Firm do
  subject(:numismatic_firm) { described_class.new city: "city", name: "name" }

  it "has properties" do
    expect(numismatic_firm.city).to eq("city")
    expect(numismatic_firm.name).to eq("name")
  end
end
