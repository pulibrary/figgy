# frozen_string_literal: true
require "rails_helper"

RSpec.describe RefreshArchivalCollectionJob do
  describe "#perform" do
    let(:collection_code) { "C0652" }

    it "enqueues refresh metadata jobs" do
      stub_findingaid(pulfa_id: "C0652_c0383")
      stub_findingaid(pulfa_id: "C0652_c0377")
      resource1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C0652_c0383", archival_collection_code: collection_code)
      resource2 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "C0652_c0377", archival_collection_code: collection_code)
      described_class.perform_now(collection_code: collection_code)
      expect(RefreshRemoteMetadataJob).to have_been_enqueued.twice
      expect(RefreshRemoteMetadataJob).to have_been_enqueued.with(id: resource1.id.to_s)
      expect(RefreshRemoteMetadataJob).to have_been_enqueued.with(id: resource2.id.to_s)
    end
  end
end
