# frozen_string_literal: true
require 'rails_helper'

describe FolderWorkflow do
  subject(:workflow) { described_class.new 'needs_qa' }

  describe 'ingest workflow' do
    it 'proceeds through ingest workflow' do
      # initial state: needs_qa
      expect(workflow.needs_qa?).to be true
      expect(workflow.may_complete?).to be true
      expect(workflow.complete?).to be false
      expect(workflow.suppressed?).to eq false

      expect(workflow.complete).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_submit_for_qa?).to eq true
      expect(workflow.needs_qa?).to eq false
      expect(workflow.suppressed?).to eq false

      expect(workflow.submit_for_qa).to eq true
      expect(workflow.needs_qa?).to eq true
      expect(workflow.complete?).to eq false
      expect(workflow.may_complete?).to eq true
      expect(workflow.suppressed?).to eq false
    end
  end
end
