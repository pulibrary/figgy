# frozen_string_literal: true
require "rails_helper"

describe MosaicJob do
  let(:mosaic_service) { instance_double(TileMetadataService) }

  before do
    allow(mosaic_service).to receive(:path)
    allow(TileMetadataService).to receive(:new).and_return(mosaic_service)
  end

  describe "#perform" do
    context "when a MosaicJon is not already running" do
      with_queue_adapter :inline

      it "runs the TileMetadataService" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
        described_class.perform_now(raster_set.id)
        expect(mosaic_service).to have_received(:path)
      end
    end

    context "when a MosaicJob is already running" do
      it "does not run the TileMetadataService and instead retries the job" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
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
                 "arguments" => [raster_set.id.to_s],
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
        described_class.perform_now(raster_set.id.to_s)
        expect(mosaic_service).not_to have_received(:path)
      end
    end
  end
end
