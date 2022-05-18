# frozen_string_literal: true
require "rails_helper"

RSpec.describe ExtractArchivalCollectionCodeJob do
  with_queue_adapter :inline

  let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C0652_c0389") }
  let(:logger) { instance_double Logger }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  before do
    allow(logger).to receive(:info)
    stub_findingaid(pulfa_id: "C0652_c0389")
    resource
  end

  describe ".perform" do
    it "extracts an archival collection code from the source_metadata_identifier" do
      described_class.perform_now(logger: logger)
      expect(query_service.find_by(id: resource.id).archival_collection_code).to eq "C0652"
    end
  end
end
