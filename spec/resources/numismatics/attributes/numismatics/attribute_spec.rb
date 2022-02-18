# frozen_string_literal: true

require "rails_helper"

describe Numismatics::Attribute do
  subject(:artist) { described_class.new(description: "description", name: "name") }

  it "has properties" do
    expect(artist.description).to eq(["description"])
    expect(artist.name).to eq(["name"])
  end
end
