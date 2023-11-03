# frozen_string_literal: true
require "rails_helper"

describe MosaicJob do
  with_queue_adapter :inline

  let(:mosaic_service) { instance_double(TileMetadataService) }

  before do
    allow(mosaic_service).to receive(:path)
    allow(TileMetadataService).to receive(:new).and_return(mosaic_service)
  end

  describe "#perform" do
    it "runs the TileMetadataService" do
      raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
      described_class.perform_now(raster_set.id)
      expect(mosaic_service).to have_received(:path)
    end

    context "when a MosaicJob is already enqueued" do
      before do
      end
      it "does not run the TileMetadataService" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files)
        job_item = {
          "retry" => true,
          "queue" => "low",
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
                         "enqueued_at" => "2023-11-03T18:26:41Z" }],
          "jid" => "73ff1c5050ce8adba5feab66",
          "created_at" => 1_699_036_001.1491642,
          "enqueued_at" => 1_699_036_001.1493726
        }
        job_record = instance_double(Sidekiq::JobRecord, item: job_item)
        allow(Sidekiq::Queue).to receive(:new).and_return([job_record])
        described_class.perform_now(raster_set.id)
        expect(mosaic_service).not_to have_received(:path)
      end
    end
  end
end
