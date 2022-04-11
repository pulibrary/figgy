# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Note do
  subject(:artist) { described_class.new(note: "also attributed to Andronicus III", type: "attribution") }

  it "has properties" do
    expect(artist.note).to eq(["also attributed to Andronicus III"])
    expect(artist.type).to eq(["attribution"])
  end
end
