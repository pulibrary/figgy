require "rails_helper"
require "ruby-progressbar/outputs/null"

RSpec.describe Reindexer do
  let(:solr_adapter) { Valkyrie::MetadataAdapter.find(:reindex_solr) }
  let(:postgres_adapter) { Valkyrie::MetadataAdapter.find(:postgres) }
  let(:logger) { instance_double("Logger").as_null_object }
  let(:progress_bar) { ProgressBar.create(output: ProgressBar::Outputs::Null) }

  before do
    allow(ProgressBar).to receive(:create).and_return(progress_bar)
    Valkyrie.logger.level = Logger::ERROR
  end

  describe ".reindex_all" do
    context "when there are records not in solr" do
      it "puts them in solr" do
        resource = FactoryBot.build(:scanned_resource)
        output = postgres_adapter.persister.save(resource: resource)
        expect { solr_adapter.query_service.find_by(id: output.id) }.to raise_error Valkyrie::Persistence::ObjectNotFoundError

        described_class.reindex_all(logger: logger, wipe: true)

        expect { solr_adapter.query_service.find_by(id: output.id) }.not_to raise_error
      end
    end
    context "when asked to reindex records updated in the last day" do
      it "only indexes those" do
        # Recently created item.
        resource = FactoryBot.create_for_repository(:scanned_resource)
        # resource2 won't be updated in the last day.
        resource2 = Timecop.travel(Time.current - 2.days) do
          FactoryBot.create_for_repository(:scanned_resource)
        end
        resource3 = Timecop.travel(Time.current - 3.days) do
          FactoryBot.create_for_repository(:scanned_resource)
        end
        # Update resource3 to have a more recent updated_at
        ChangeSetPersister.default.save(change_set: ChangeSet.for(resource3))

        # Wipe out Solr so we can count indexed records.
        described_class.reindex_all(logger: logger, wipe: false, updated_since: 1.day.ago)

        solr_resources = solr_adapter.query_service.find_all.to_a
        expect(solr_resources.length).to eq 2
        expect(solr_resources.map(&:id)).to include resource.id, resource3.id
        expect(solr_resources.map(&:id)).not_to include resource2.id
      end
    end
    it "reindexes multiple records" do
      5.times do
        postgres_adapter.persister.save(resource: FactoryBot.build(:scanned_resource))
      end

      described_class.reindex_all(logger: logger, wipe: true, batch_size: 2)
      expect(solr_adapter.query_service.find_all.to_a.length).to eq 5
    end

    context "when there are records in solr which are no longer in postgres" do
      it "gets rid of them" do
        resource = FactoryBot.build(:scanned_resource)
        solr_adapter.persister.save(resource: resource)

        described_class.reindex_all(logger: logger, wipe: true)

        expect(solr_adapter.connection.get("select", params: { q: "*:*" })["response"]["numFound"]).to eq 0
      end
      it "doesn't get rid of them if you tell it not to wipe" do
        resource = FactoryBot.build(:scanned_resource)
        solr_adapter.persister.save(resource: resource)

        described_class.reindex_all(logger: logger, wipe: false)

        expect(solr_adapter.connection.get("select", params: { q: "*:*" })["response"]["numFound"]).to eq 1
      end
    end

    context "when rsolr raises errors" do
      let!(:resources) do
        Array.new(5) do
          postgres_adapter.persister.save(resource: FactoryBot.build(:scanned_resource))
        end
      end
      let(:indexer) do
        described_class.new(
          solr_adapter: Valkyrie::MetadataAdapter.find(:index_solr),
          query_service: Valkyrie::MetadataAdapter.find(:postgres).query_service,
          logger: logger,
          wipe: true
        )
      end

      let(:filtered_indexer) do
        Reindexer::FilteredIndexer.new(
          indexer: indexer,
          except_models: []
        )
      end

      before do
        allow(Reindexer::FilteredIndexer).to receive(:new).and_return(filtered_indexer)
        allow(filtered_indexer).to receive(:single_index_persist).and_call_original
      end

      it "tolerates RSolr::Error::ConnectionRefused, logging bad id" do
        error = RSolr::Error::ConnectionRefused.new({ uri: URI::HTTP.build(host: "example.com") })
        allow(filtered_indexer).to receive(:multi_index_persist).and_raise error
        allow(filtered_indexer).to receive(:single_index_persist).with(resources[0]).and_raise error

        indexer.reindex_all
        expect(logger).to have_received(:error).with("Could not index #{resources[0].id} due to RSolr::Error::ConnectionRefused")
      end

      it "tolerates RSolr::Error::Http, logging bad id" do
        error = RSolr::Error::Http.new({ uri: URI::HTTP.build(host: "example.com") }, nil)
        allow(filtered_indexer).to receive(:multi_index_persist).and_raise error
        allow(filtered_indexer).to receive(:single_index_persist).with(resources[0]).and_raise error

        indexer.reindex_all
        expect(logger).to have_received(:error).with("Could not index #{resources[0].id} due to RSolr::Error::Http")
      end
    end
  end

  describe ".reindex_works" do
    context "when there are disallowed models" do
      it "doesn't index them" do
        postgres_adapter.persister.save(resource: FactoryBot.build(:file_set))
        scanned_resource = postgres_adapter.persister.save(resource: FactoryBot.build(:scanned_resource))
        postgres_adapter.persister.save(resource: FactoryBot.build(:preservation_object))
        described_class.reindex_works(logger: logger, wipe: true)
        expect(solr_adapter.query_service.find_all.map(&:id)).to eq([scanned_resource.id])
      end
    end
  end
end
