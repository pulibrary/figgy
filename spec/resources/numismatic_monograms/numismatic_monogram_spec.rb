# frozen_string_literal: true
require "rails_helper"

describe NumismaticMonogram do
  subject(:reference) { described_class.new title: "monogram" }

  it "has properties" do
    expect(reference.title).to eq(["monogram"])
  end
end
