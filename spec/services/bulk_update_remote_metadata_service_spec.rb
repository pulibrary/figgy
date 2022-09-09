# frozen_string_literal: true
require "rails_helper"

RSpec.describe BulkUpdateRemoteMetadataService do
  describe ".call" do
    it "queues VoyagerUpdateJobs for everything with remote metadata" do
      stub_catalog(bib_id: "123456")
      resource1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: nil)
      resource3 = FactoryBot.create_for_repository(:scanned_map, source_metadata_identifier: "123456")
      FactoryBot.create_for_repository(:file_set)
      allow(VoyagerUpdateJob).to receive(:perform_later)

      described_class.call

      expect(VoyagerUpdateJob).to have_received(:perform_later).with(a_collection_containing_exactly(resource1.id.to_s, resource3.id.to_s))
    end
    it "can set a batch size" do
      stub_catalog(bib_id: "123456")
      resource1 = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456")
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: nil)
      resource3 = FactoryBot.create_for_repository(:scanned_map, source_metadata_identifier: "123456")
      FactoryBot.create_for_repository(:file_set)
      allow(VoyagerUpdateJob).to receive(:perform_later)

      described_class.call(batch_size: 1)

      expect(VoyagerUpdateJob).to have_received(:perform_later).with([resource1.id.to_s])
      expect(VoyagerUpdateJob).to have_received(:perform_later).with([resource3.id.to_s])
    end
  end
end
