# frozen_string_literal: true

require "rails_helper"

RSpec.describe StateValidator do
  subject(:validator) { described_class.new }

  describe "#validate" do
    let(:errors) { instance_double("Errors") }
    before do
      allow(errors).to receive(:add)
    end
    ["pending", "metadata_review", "final_review", "complete", "flagged", "takedown"].each do |state|
      context "when state is #{state}" do
        it "does not add errors" do
          record = build_record(old_state: state, new_state: state)
          validator.validate(record)
          expect(errors).not_to have_received(:add)
        end
      end
    end

    context "when state is blank" do
      it "adds errors" do
        record = build_record(old_state: nil, new_state: nil)
        validator.validate(record)
        expect(errors).to have_received(:add).with(:state, " is not a valid state")
      end
    end

    context "when new state is not acceptable" do
      it "adds errors" do
        record = build_record(old_state: "pending", new_state: "bad")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:state, "bad is not a valid state")
      end
    end

    context "when transition is not acceptable" do
      it "adds errors" do
        record = build_record(old_state: "pending", new_state: "takedown")
        validator.validate(record)
        expect(errors).to have_received(:add).with(:state, "Cannot transition from pending to takedown")
      end
    end
  end

  def build_record(old_state:, new_state:)
    record = instance_double ScannedResourceChangeSet
    allow(record).to receive(:workflow_class).and_return(BookWorkflow)
    allow(record).to receive(:errors).and_return(errors)
    allow(record).to receive(:old_state).and_return(old_state)
    allow(record).to receive(:new_state).and_return(new_state)
    allow(record).to receive(:state_changed?).and_return(old_state != new_state)
    record
  end
end
