# frozen_string_literal: true

require "rails_helper"

RSpec.describe AuthToken, type: :model do
  it "creates a token on create" do
    expect(described_class.create(label: "Test", group: ["admin"]).token).not_to be_blank
  end

  it "serializes the group the token grants" do
    token = described_class.create(label: "Test", group: ["admin"])
    expect(token.reload.group).to eq ["admin"]
  end

  it "strips blanks when setting group" do
    token = described_class.create(label: "Test", group: ["admin", ""])
    expect(token.reload.group).to eq ["admin"]
  end
end
