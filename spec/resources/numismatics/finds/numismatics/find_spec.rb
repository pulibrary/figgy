# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Find do
  subject(:find) { described_class.new date: "9/10/2011", feature: "Kaoussie" }

  it "has properties" do
    expect(find.date).to eq(["9/10/2011"])
    expect(find.feature).to eq(["Kaoussie"])
  end

  it "has a title" do
    expect(find.title).to include "Find: "
  end
end
