# frozen_string_literal: true
require 'rails_helper'

describe BookWorkflow do
  subject(:workflow) { described_class.new 'pending' }

  describe 'ingest workflow' do
    it 'proceeds through ingest workflow' do
      # initial state: pending
      expect(workflow.pending?).to be true
      expect(workflow.may_finalize_digitization?).to be true
      expect(workflow.may_finalize_metadata?).to be false
      expect(workflow.may_complete?).to be false
      expect(workflow.may_takedown?).to be false
      expect(workflow.may_flag?).to be false
      expect(workflow.suppressed?).to be true

      # digitization signoff moves to metadata review
      expect(workflow.finalize_digitization).to be true
      expect(workflow.metadata_review?).to be true
      expect(workflow.may_finalize_digitization?).to be false
      expect(workflow.may_finalize_metadata?).to be true
      expect(workflow.may_complete?).to be false
      expect(workflow.may_takedown?).to be false
      expect(workflow.may_flag?).to be false
      expect(workflow.suppressed?).to be true

      # metadata signoff moves to final review
      expect(workflow.finalize_metadata).to be true
      expect(workflow.final_review?).to be true
      expect(workflow.may_finalize_digitization?).to be false
      expect(workflow.may_finalize_metadata?).to be false
      expect(workflow.may_complete?).to be true
      expect(workflow.may_takedown?).to be false
      expect(workflow.may_flag?).to be false
      expect(workflow.suppressed?).to be true

      # final signoff moves to complete
      expect(workflow.complete).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_finalize_digitization?).to be false
      expect(workflow.may_finalize_metadata?).to be false
      expect(workflow.may_complete?).to be false
      expect(workflow.may_takedown?).to be true
      expect(workflow.may_flag?).to be true
      expect(workflow.suppressed?).to be false
    end
  end

  describe 'takedown workflow' do
    subject(:workflow) { described_class.new :complete }
    it 'goes back and forth between complete and takedown' do
      expect(workflow.complete?).to be true
      expect(workflow.may_restore?).to be false
      expect(workflow.may_takedown?).to be true
      expect(workflow.suppressed?).to be false

      expect(workflow.takedown).to be true
      expect(workflow.takedown?).to be true
      expect(workflow.may_restore?).to be true
      expect(workflow.may_takedown?).to be false
      expect(workflow.suppressed?).to be true

      expect(workflow.restore).to be true
      expect(workflow.complete?).to be true
      expect(workflow.may_restore?).to be false
      expect(workflow.may_takedown?).to be true
      expect(workflow.suppressed?).to be false
    end
  end

  describe 'flagging workflow' do
    subject(:workflow) { described_class.new :complete }
    it 'goes back and forth between flagged and unflagged' do
      expect(workflow.complete?).to be true
      expect(workflow.may_flag?).to be true
      expect(workflow.may_unflag?).to be false
      expect(workflow.suppressed?).to be false

      expect(workflow.flag).to be true
      expect(workflow.may_flag?).to be false
      expect(workflow.may_unflag?).to be true
      expect(workflow.suppressed?).to be false

      expect(workflow.unflag).to be true
      expect(workflow.may_flag?).to be true
      expect(workflow.may_unflag?).to be false
      expect(workflow.suppressed?).to be false
    end
  end
end
