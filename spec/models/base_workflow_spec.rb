# frozen_string_literal: true
require "rails_helper"

describe BaseWorkflow do
  describe ".valid_states_for_classes" do
    it "returns an empty Hash" do
      expect(described_class.valid_states_for_classes).to eq({})
    end
  end

  describe ".state_for_related" do
    it "returns the state" do
      expect(described_class.state_for_related(klass: nil, state: "complete")).to eq "complete"
    end
  end

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
end
