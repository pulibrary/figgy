# frozen_string_literal: true
require "rails_helper"

RSpec.describe WorkflowRegistry do
  describe ".all_states" do
    it "returns a list of all states" do
      expect(described_class.all_states).to contain_exactly "all_in_production", "complete", "draft", "final_review",
                                                            "flagged", "metadata_review", "needs_qa", "new", "pending", "ready_to_ship", "received", "shipped", "takedown"
    end
  end

  describe ".public_read_states" do
    it "returns a list of public read states" do
      expect(described_class.public_read_states).to contain_exactly "complete", "flagged", "needs_qa"
    end
  end

  describe ".workflows" do
    it "lists all descendents of BaseWorkflow" do
      expect(described_class.workflows).to contain_exactly(*BaseWorkflow.descendants)
    end
  end
end
