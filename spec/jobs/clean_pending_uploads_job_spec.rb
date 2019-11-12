# frozen_string_literal: true
require "rails_helper"

RSpec.describe CleanPendingUploadsJob do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:resource1) do
    FactoryBot.create_for_repository(
      :pending_scanned_resource,
      pending_uploads: []
    )
  end
  let(:resource_id) { resource1.id }

  describe "#perform" do
    before do
      allow(Valkyrie.logger).to receive(:info)
      resource1
    end

    it "deletes resources with failed file uploads" do
      described_class.perform_now
      expect { query_service.find_by(id: resource_id) }.to raise_error(Valkyrie::Persistence::ObjectNotFoundError)
      expect(Valkyrie.logger).to have_received(:info).with("Deleted a resource with failed uploads with the ID: #{resource_id}")
    end
  end
end
