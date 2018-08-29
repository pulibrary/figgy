# frozen_string_literal: true
require "rails_helper"

describe FolderWorkflow do
  subject(:workflow) { described_class.new "needs_qa" }

  describe "ingest workflow" do
    it "proceeds through ingest workflow" do
      # initial state: needs_qa
      expect(workflow.needs_qa?).to be true
<<<<<<< HEAD
      expect(workflow.may_make_complete?).to be true
      expect(workflow.complete?).to be false

      expect(workflow.make_complete).to be true
=======
      expect(workflow.may_complete?).to be true
      expect(workflow.complete?).to be false

      expect(workflow.complete).to be true
>>>>>>> d8616123... adds lux order manager to figgy
      expect(workflow.complete?).to be true
      expect(workflow.may_submit_for_qa?).to eq true
      expect(workflow.needs_qa?).to eq false

      expect(workflow.submit_for_qa).to eq true
      expect(workflow.needs_qa?).to eq true
      expect(workflow.complete?).to eq false
<<<<<<< HEAD
      expect(workflow.may_make_complete?).to eq true
=======
      expect(workflow.may_complete?).to eq true
>>>>>>> d8616123... adds lux order manager to figgy
    end
  end

  describe "access states" do
    it "provides a list of read-accessible states" do
      expect(described_class.public_read_states).to contain_exactly "complete", "needs_qa"
    end

    it "provides a list of manifest-publishable states" do
      expect(described_class.manifest_states).to contain_exactly "complete"
    end

    it "provides a list of states valid for minting a new ARK" do
      expect(described_class.ark_mint_states).to be_empty
    end
  end
end
