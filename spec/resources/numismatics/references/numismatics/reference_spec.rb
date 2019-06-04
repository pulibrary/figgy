# frozen_string_literal: true
require "rails_helper"

describe Numismatics::Reference do
  subject(:reference) { described_class.new title: "reference", short_title: "ref" }

  it "has properties" do
    expect(reference.title).to eq(["reference"])
    expect(reference.short_title).to eq(["ref"])
  end
end
