# frozen_string_literal: true
require 'rails_helper'

describe BoxWorkflow do
  subject(:workflow) { described_class.new 'new' }

  describe 'ingest workflow' do
    it 'proceeds through ingest workflow' do
      expect(workflow.new?).to be true
      expect(workflow.may_ready_to_ship?).to be true
      expect(workflow.may_shipped?).to be false
      expect(workflow.may_received?).to be false
      expect(workflow.may_all_in_production?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.ready_to_ship).to be true
      expect(workflow.may_ready_to_ship?).to be false
      expect(workflow.may_shipped?).to be true
      expect(workflow.may_received?).to be false
      expect(workflow.may_all_in_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be true
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.shipped).to be true
      expect(workflow.may_ready_to_ship?).to be false
      expect(workflow.may_shipped?).to be false
      expect(workflow.may_received?).to be true
      expect(workflow.may_all_in_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be true
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq false

      expect(workflow.received).to be true
      expect(workflow.may_ready_to_ship?).to be false
      expect(workflow.may_shipped?).to be false
      expect(workflow.may_received?).to be false
      expect(workflow.may_all_in_production?).to be true
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq true
      expect(workflow.all_in_production?).to eq false

      expect(workflow.all_in_production).to be true
      expect(workflow.may_ready_to_ship?).to be false
      expect(workflow.may_shipped?).to be false
      expect(workflow.may_received?).to be false
      expect(workflow.may_all_in_production?).to be false
      expect(workflow.new?).to be false
      expect(workflow.ready_to_ship?).to be false
      expect(workflow.shipped?).to be false
      expect(workflow.received?).to eq false
      expect(workflow.all_in_production?).to eq true

      expect(workflow.suppressed?).to eq false
      expect(workflow.valid_states).to eq [:new, :ready_to_ship, :shipped, :received, :all_in_production].map(&:to_s)
    end
  end
end
