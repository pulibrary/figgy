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
    let(:handle) { "test-handle" }
    let(:dspace_api_token) { "test-token" }
    let(:ingest_service) { instance_double(DspaceIngester) }
    let(:ingest_service_class) { class_double(DspaceIngester) }
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:collection_ids) { [collection.id] }
    let(:job_args) do
      {
        handle: handle,
        dspace_api_token: dspace_api_token,
        ingest_service: ingest_service_class,
        collection_ids: collection_ids
      }
    end

    before do
      allow(ingest_service).to receive(:ingest!)
      allow(ingest_service_class).to receive(:new).with(any_args).and_return(ingest_service)
    end

    it "delegates to DspaceIngester" do
      described_class.perform_now(**job_args)

      expect(ingest_service_class).to have_received(:new)
      expect(ingest_service).to have_received(:ingest!)
    end

    context "when specifying an unsupported Class" do
      before do
        allow(Rails.logger).to receive(:warn)
      end

      xit "logs a warning message" do
        described_class.perform_now(**job_args)

        expect(ingest_service_class).to have_received(:new)
        expect(ingest_service).to have_received(:ingest!)
        expect(Rails.logger).to have_received(:warn).with("Ingesting a folder with an unsupported class: Playlist")
      end
    end
  end
end
