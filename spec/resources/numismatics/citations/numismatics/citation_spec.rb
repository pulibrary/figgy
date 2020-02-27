# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Citation do
  subject(:numismatic_citation) { described_class.new part: "first", number: "2", citation_type: "Exhibition" }

  it "has properties" do
    expect(numismatic_citation.part).to eq(["first"])
    expect(numismatic_citation.number).to eq(["2"])
    expect(numismatic_citation.citation_type).to eq(["Exhibition"])
  end
end
