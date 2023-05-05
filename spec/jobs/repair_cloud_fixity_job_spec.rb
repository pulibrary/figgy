# frozen_string_literal: true
require "rails_helper"

RSpec.describe RepairCloudFixityJob do
  describe "#perform" do
    it "invokes the RepairCloudFixity service" do
      allow(RepairCloudFixity).to receive(:run)
      event = FactoryBot.create_for_repository(:cloud_fixity_event)

      described_class.perform_now(event: event)
      expect(RepairCloudFixity).to have_received(:run).with(event: event)
    end
  end
end
