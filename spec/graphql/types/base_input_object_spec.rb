# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::BaseInputObject do
  it "has no arguments defined" do
    expect(described_class.arguments).to eq({})
  end
end
