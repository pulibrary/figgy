# frozen_string_literal: true

require "rails_helper"

describe DraftCompleteWorkflow do
  subject(:workflow) { described_class.new "draft" }

  describe "ingest workflow" do
    it "proceeds through ingest workflow" do
      # initial state: draft
      expect(workflow.draft?).to be true
      expect(workflow.may_make_complete?).to be true
      expect(workflow.complete?).to be false
      expect(workflow.valid_transitions).to contain_exactly "complete"

      expect(workflow.make_complete).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_make_draft?).to eq true
      expect(workflow.draft?).to eq false
      expect(workflow.valid_transitions).to contain_exactly "draft"

      expect(workflow.make_draft).to eq true
      expect(workflow.draft?).to eq true
      expect(workflow.complete?).to eq false
      expect(workflow.may_make_complete?).to eq true
      expect(workflow.valid_transitions).to contain_exactly "complete"
    end
  end

  it "reports valid states" do
    expect(workflow.valid_states).to eq %w[draft complete]
  end

  describe "access states" do
    it "provides a list of read-accessible states" do
      expect(described_class.public_read_states).to contain_exactly "complete"
    end

    it "provides a list of manifest-completeable states" do
      expect(described_class.manifest_states).to contain_exactly "complete"
    end

    it "provides a list of states valid for minting a new ARK" do
      expect(described_class.ark_mint_states).to contain_exactly "complete"
    end
  end
end
