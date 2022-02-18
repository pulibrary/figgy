# frozen_string_literal: true

require "rails_helper"

describe Numismatics::Person do
  subject(:numismatic_place) do
    described_class.new(name1: "name1",
      name2: "name2",
      epithet: "epithet",
      family: "family",
      born: "born",
      died: "died",
      class_of: "class of",
      years_active_start: "years active start",
      years_active_end: "years active end",
      replaces: "ruler-123")
  end

  it "has properties" do
    expect(numismatic_place.name1).to eq(["name1"])
    expect(numismatic_place.name2).to eq(["name2"])
    expect(numismatic_place.epithet).to eq(["epithet"])
    expect(numismatic_place.family).to eq(["family"])
    expect(numismatic_place.born).to eq(["born"])
    expect(numismatic_place.died).to eq(["died"])
    expect(numismatic_place.class_of).to eq(["class of"])
    expect(numismatic_place.years_active_start).to eq(["years active start"])
    expect(numismatic_place.years_active_end).to eq(["years active end"])
    expect(numismatic_place.replaces).to eq(["ruler-123"])
  end
end
