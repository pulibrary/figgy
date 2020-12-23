# frozen_string_literal: true
require "rails_helper"

describe GeoWorkflow do
  subject(:workflow) { described_class.new "pending" }

  describe "ingest workflow" do
    it "proceeds through ingest workflow" do
      # initial state: pending
      expect(workflow.pending?).to be true
      expect(workflow.may_finalize_digitization?).to be true
      expect(workflow.may_make_complete?).to be true
      expect(workflow.may_mark_for_takedown?).to be false
      expect(workflow.may_flag?).to be false

      # digitization signoff moves to final review
      expect(workflow.finalize_digitization).to be true
      expect(workflow.final_review?).to be true
      expect(workflow.may_finalize_digitization?).to be false
      expect(workflow.may_make_complete?).to be true
      expect(workflow.may_mark_for_takedown?).to be false
      expect(workflow.may_flag?).to be false

      # final signoff moves to complete
      expect(workflow.make_complete).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_finalize_digitization?).to be false
      expect(workflow.may_make_complete?).to be false
      expect(workflow.may_mark_for_takedown?).to be true
      expect(workflow.may_flag?).to be true
    end
  end

  describe "takedown workflow" do
    subject(:workflow) { described_class.new :complete }
    it "goes back and forth between complete and takedown" do
      expect(workflow.complete?).to be true
      expect(workflow.may_restore?).to be false
      expect(workflow.may_mark_for_takedown?).to be true

      expect(workflow.mark_for_takedown).to be true
      expect(workflow.takedown?).to be true
      expect(workflow.may_restore?).to be true
      expect(workflow.may_mark_for_takedown?).to be false

      expect(workflow.restore).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_restore?).to be false
      expect(workflow.may_mark_for_takedown?).to be true
    end
  end

  describe "flagging workflow" do
    subject(:workflow) { described_class.new :complete }
    it "goes back and forth between flagged and unflagged" do
      expect(workflow.complete?).to be true
      expect(workflow.may_flag?).to be true
      expect(workflow.may_unflag?).to be false

      expect(workflow.flag).to be true
      expect(workflow.may_flag?).to be false
      expect(workflow.may_unflag?).to be true

      expect(workflow.unflag).to be true
      expect(workflow.may_flag?).to be true
      expect(workflow.may_unflag?).to be false
    end
  end

  describe "access states" do
    it "provides a list of read-accessible states" do
      expect(described_class.public_read_states).to contain_exactly "complete", "flagged"
    end

    it "provides a list of manifest-publishable states" do
      expect(described_class.manifest_states).to contain_exactly "complete", "flagged"
    end

    it "provides a list of states valid for minting a new ARK" do
      expect(described_class.ark_mint_states).to contain_exactly "complete"
    end
  end
end
