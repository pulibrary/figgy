# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe TransactionCompositePersister do
  let(:postgres_adapter) { Valkyrie::MetadataAdapter.find(:postgres) }
  let(:solr_adapter) { Valkyrie::MetadataAdapter.find(:index_solr) }
  let(:query_service) { postgres_adapter.query_service }
  let(:persister) do
    described_class.new(
      postgres_adapter.persister,
      solr_adapter.persister
    )
  end
  it_behaves_like "a Valkyrie::Persister"

  describe "#save" do
    context "when the solr adapter fails" do
      it "rolls back the transaction" do
        resource = FactoryBot.build(:scanned_resource)
        allow(solr_adapter.persister).to receive(:save).and_raise("Broken")

        expect { persister.save(resource: resource) }.to raise_error("Broken")

        expect(solr_adapter.query_service.find_all.to_a.size).to eq 0
        expect(postgres_adapter.query_service.find_all.to_a.size).to eq 0
      end
    end
  end

  describe "#save_all" do
    context "when the solr adapter fails" do
      it "rolls back the transaction" do
        resource1 = FactoryBot.build(:scanned_resource)
        resource2 = FactoryBot.build(:scanned_resource)
        # Stub save because the implementation of save_all is to iterate and
        # call save for every resource.
        allow(solr_adapter.persister).to receive(:save).and_raise("Broken")
        allow(solr_adapter.persister).to receive(:save_all).and_raise("Broken")

        expect { persister.save_all(resources: [resource1, resource2]) }.to raise_error("Broken")

        expect(solr_adapter.query_service.find_all.to_a.size).to eq 0
        expect(postgres_adapter.query_service.find_all.to_a.size).to eq 0
      end
    end
  end

  describe "#delete" do
    context "when the solr adapter fails" do
      it "rolls back the transaction" do
        resource1 = FactoryBot.build(:scanned_resource)
        allow(solr_adapter.persister).to receive(:delete).and_raise("Broken")
        output = persister.save(resource: resource1)

        expect { persister.delete(resource: output) }.to raise_error("Broken")

        expect(solr_adapter.query_service.find_all.to_a.size).to eq 1
        expect(postgres_adapter.query_service.find_all.to_a.size).to eq 1
      end
    end
  end
end
