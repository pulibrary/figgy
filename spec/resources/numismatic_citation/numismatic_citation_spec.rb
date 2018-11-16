# frozen_string_literal: true
require "rails_helper"

describe NumismaticCitation do
  subject(:citation) { described_class.new part: "first", number: "2" }

  it "has properties" do
    expect(citation.part).to eq(["first"])
    expect(citation.number).to eq(["2"])
  end
end
