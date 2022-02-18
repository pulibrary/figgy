# frozen_string_literal: true

require "rails_helper"

RSpec.describe Types::BaseInterface do
  it "has no fields defined" do
    expect(described_class.fields).to eq({})
  end
end
