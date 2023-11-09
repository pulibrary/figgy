# frozen_string_literal: true
require "rails_helper"

describe MosaicJob do
  let(:mosaic_service) { instance_double(TileMetadataService) }
  let(:query_service) { ChangeSetPersister.default.query_service }

  before do
    allow(mosaic_service).to receive(:path)
    allow(TileMetadataService).to receive(:new).and_return(mosaic_service)
  end

  describe "#perform" do
    context "when a MosaicJob is not currently running" do
      it "runs the TileMetadataService" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: fingerprint)
        expect(mosaic_service).to have_received(:path)
      end

      context "with  mosaic fingerprints that don't match" do
        it "return without running the TileMetadataService and does not re-enqueue itself" do
          raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
          expect { described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: "out-of-date") }.not_to have_enqueued_job(described_class)
          expect(mosaic_service).not_to have_received(:path)
        end
      end
    end

    context "when a MosaicJob is already running" do
      it "does not run the TileMetadataService and instead re-enqueues itself" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
        fingerprint = query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id)
        worker_record = [nil, nil, {
          "queue" => "low",
          "payload" =>
            { "retry" => true,
              "queue" => "default",
              "class" => "ActiveJob::QueueAdapters::SidekiqAdapter::JobWrapper",
              "wrapped" => "MosaicJob",
              "args" =>
              [{ "job_class" => "MosaicJob",
                 "job_id" => "12cfd9ff-5555-6666-8892-f44d386967d3",
                 "provider_job_id" => nil,
                 "queue_name" => "low",
                 "priority" => nil,
                 "arguments" => [{ "resource_id" => raster_set.id.to_s, "fingerprint" => fingerprint }],
                 "executions" => 0,
                 "exception_executions" => {},
                 "locale" => "en",
                 "timezone" => "UTC",
                 "enqueued_at" => "2023-11-04T03:36:39Z" }],
              "jid" => "69bce24959abb10c538da41b",
              "created_at" => 1_699_068_999.2283602,
              "enqueued_at" => 1_699_068_999.2287548 },
          "run_at" => 1_699_069_060
        }]
        allow(Sidekiq::Workers).to receive(:new).and_return([worker_record])
        expect { described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: fingerprint) }.to have_enqueued_job(described_class)
        expect(mosaic_service).not_to have_received(:path)
      end
    end
  end
end
