# frozen_string_literal: true
require "rails_helper"

RSpec.describe WorkflowRegistry do
  describe ".register" do
    before do
      class MyResource < Resource; end
      class MyWorkflow; end
    end

    after do
      described_class.unregister(MyResource)
      Object.send(:remove_const, :MyResource)
      Object.send(:remove_const, :MyWorkflow)
    end

    it "adds an entry for the pair" do
      expect(described_class.register(resource_class: MyResource, workflow_class: MyWorkflow)).to be true
      expect(described_class.workflow_for(MyResource)).to eq MyWorkflow
    end
  end

  describe ".workflow_for" do
    context "when given a resource that is registered" do
      it "returns the workflow class" do
<<<<<<< HEAD
        expect(described_class.workflow_for(SimpleResource)).to eq DraftCompleteWorkflow
=======
        expect(described_class.workflow_for(SimpleResource)).to eq DraftPublishWorkflow
>>>>>>> d8616123... adds lux order manager to figgy
      end
    end

    context "when given a resource that isn't registered" do
      before { class TotallyNotAResource; end }
      after { Object.send(:remove_const, :TotallyNotAResource) }

      it "throws exception" do
        expect { described_class.workflow_for(TotallyNotAResource) }.to raise_error(WorkflowRegistry::EntryNotFound, "TotallyNotAResource")
      end
    end
  end

  describe ".all_states" do
    it "returns a list of all states" do
      expect(described_class.all_states).to contain_exactly "all_in_production", "complete", "draft", "final_review",
<<<<<<< HEAD
                                                            "flagged", "metadata_review", "needs_qa", "new", "pending", "ready_to_ship", "received", "shipped", "takedown"
=======
                                                            "flagged", "metadata_review", "needs_qa", "new", "pending", "published", "ready_to_ship", "received", "shipped", "takedown"
>>>>>>> d8616123... adds lux order manager to figgy
    end
  end

  describe ".public_read_states" do
    it "returns a list of public read states" do
<<<<<<< HEAD
      expect(described_class.public_read_states).to contain_exactly "complete", "flagged", "needs_qa"
=======
      expect(described_class.public_read_states).to contain_exactly "complete", "flagged", "needs_qa", "published"
>>>>>>> d8616123... adds lux order manager to figgy
    end
  end
end
