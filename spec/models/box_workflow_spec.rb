# frozen_string_literal: true

require "rails_helper"

describe BoxWorkflow do
  subject(:workflow) { described_class.new "new" }

  describe "ingest workflow" do
    it "proceeds through ingest workflow" do
      expect(workflow.new?).to be true
      expect(workflow.may_prepare_to_ship?).to be true
      expect(workflow.may_ship?).to be false
      expect(workflow.may_mark_as_received?).to be false
      expect(workflow.may_release_into_production?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.prepare_to_ship).to be true
      expect(workflow.may_prepare_to_ship?).to be false
      expect(workflow.may_ship?).to be true
      expect(workflow.may_mark_as_received?).to be false
      expect(workflow.may_release_into_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be true
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.ship).to be true
      expect(workflow.may_prepare_to_ship?).to be false
      expect(workflow.may_ship?).to be false
      expect(workflow.may_mark_as_received?).to be true
      expect(workflow.may_release_into_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be true
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.mark_as_received).to be true
      expect(workflow.may_prepare_to_ship?).to be false
      expect(workflow.may_ship?).to be false
      expect(workflow.may_mark_as_received?).to be false
      expect(workflow.may_release_into_production?).to be true
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq true
      expect(workflow.all_in_production?).to eq false

      expect(workflow.release_into_production).to be true
      expect(workflow.may_prepare_to_ship?).to be false
      expect(workflow.may_ship?).to be false
      expect(workflow.may_mark_as_received?).to be false
      expect(workflow.may_release_into_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq true

      expect(workflow.valid_states).to eq [:new, :ready_to_ship, :shipped, :received, :all_in_production].map(&:to_s)
    end
  end

  describe "access states" do
    it "provides a list of read-accessible states" do
      expect(described_class.public_read_states).to be_empty
    end

    it "provides a list of manifest-publishable states" do
      expect(described_class.manifest_states).to contain_exactly "all_in_production"
    end

    it "provides a list of states valid for minting a new ARK" do
      expect(described_class.ark_mint_states).to be_empty
    end
  end
end
