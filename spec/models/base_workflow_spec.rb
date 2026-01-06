# frozen_string_literal: true
require "rails_helper"

describe BaseWorkflow do
  describe ".public_read_states" do
    it "returns an empty array" do
      expect(described_class.public_read_states).to eq []
    end
  end

  describe ".manifest_states" do
    it "returns an empty array" do
      expect(described_class.manifest_states).to eq []
    end
  end

  describe ".ark_mint_states" do
    it "returns an empty array" do
      expect(described_class.ark_mint_states).to eq []
    end
  end

  describe ".published_state" do
    it "returns a nil valie" do
      expect(described_class.published_state).to be_nil
    end
  end
end
