require "rails_helper"

describe MosaicJob do
  let(:mosaic_service) { instance_double(TileMetadataService) }
  let(:query_service) { ChangeSetPersister.default.query_service }
  let(:raster_set) { FactoryBot.create_for_repository(:raster_set_with_files) }
  let(:fingerprint) { query_service.custom_queries.mosaic_fingerprint_for(id: raster_set.id) }
  let(:work_set) { Sidekiq::WorkSet.new }

  before do
    allow(mosaic_service).to receive(:path)
    allow(TileMetadataService).to receive(:new).and_return(mosaic_service)
    allow(Sidekiq::WorkSet).to receive(:new).and_return(work_set)
  end

  describe "#perform" do
    context "when a MosaicJob is not currently running" do
      before do
        allow(work_set).to receive(:each).and_return([])
      end

      it "runs the TileMetadataService" do
        described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: fingerprint)
        expect(mosaic_service).to have_received(:path)
      end

      context "with  mosaic fingerprints that don't match" do
        it "return without running the TileMetadataService and does not re-enqueue itself" do
          expect { described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: "out-of-date") }.not_to have_enqueued_job(described_class)
          expect(mosaic_service).not_to have_received(:path)
        end
      end
    end

    context "when a MosaicJob is already running" do
      let(:work) { Sidekiq::Work.new(nil, nil, work_hash) }
      let(:work_hash) do
        {
          "queue" => "low",
          "payload" =>
            {
              "retry" => true,
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
              "enqueued_at" => 1_699_068_999.2287548
            }.to_json,
          "run_at" => 1_699_069_060
        }
      end

      before do
        # Mock enumberable methods on WorkSet class
        # Returns an array with one member of the form [key, tid, Sidekiq::Work]
        # See: https://github.com/sidekiq/sidekiq/blob/903aa94bf3c6ae5e858377558d75caf22c11dc39/lib/sidekiq/api.rb#L1181
        iterator = allow(work_set).to receive(:each)
        iterator.and_yield([nil, nil, work])
      end

      it "does not run the TileMetadataService and instead re-enqueues itself" do
        expect { described_class.perform_now(resource_id: raster_set.id.to_s, fingerprint: fingerprint) }.to have_enqueued_job(described_class)
        expect(mosaic_service).not_to have_received(:path)
      end
    end
  end
end
