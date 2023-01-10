# frozen_string_literal: true
require "rails_helper"

describe RestoreFromDeletionMarkerJob do
  describe "#perform" do
    before do
      allow(DeletionMarkerService).to receive(:restore)
    end

    it "runs the DeletionMarkerService" do
      id = SecureRandom.uuid
      described_class.perform_now(id)
      expect(DeletionMarkerService).to have_received(:restore).with(id)
    end
  end
end
