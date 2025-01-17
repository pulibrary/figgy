# frozen_string_literal: true

require "rails_helper"

describe IngestDspaceAssetJob do
  subject(:ingest_dspace_asset_job) { described_class.new }

  let(:bulk_ingest_service) { instance_double(BulkIngestService) }

  before do
    allow(bulk_ingest_service).to receive(:attach_dir)
    allow(BulkIngestService).to receive(:new).and_return(bulk_ingest_service)
  end

  describe "#perform" do
    let(:directory) { "test-directory" }

    it "delegates to BulkIngestService" do
      described_class.perform_now(directory: directory)

      expect(BulkIngestService).to have_received(:new)
      expect(bulk_ingest_service).to have_received(:attach_dir)
    end

    context "when specifying an unsupported Class" do
      before do
        allow(Rails.logger).to receive(:warn)
      end

      it "logs a warning message" do
        described_class.perform_now(directory: directory, class_name: "Playlist")

        expect(BulkIngestService).to have_received(:new)
        expect(bulk_ingest_service).to have_received(:attach_dir)
        expect(Rails.logger).to have_received(:warn).with("Ingesting a folder with an unsupported class: Playlist")
      end
    end
  end
end
