# frozen_string_literal: true

require "rails_helper"

RSpec.describe UpdateCicoIdsJob do
  with_queue_adapter :inline

  let(:logger) { instance_double Logger }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }
  let(:collection) { FactoryBot.create_for_repository(:collection) }

  before do
    allow(logger).to receive(:info)
  end

  describe ".perform" do
    context "when local_identifier starts with `cico:`" do
      it "updates all local identifiers starting with cico: to start with dcl:" do
        resource = FactoryBot.create_for_repository(:scanned_resource, local_identifier: "cico:1pt", member_of_collection_ids: collection.id)
        resource2 = FactoryBot.create_for_repository(:scanned_resource, local_identifier: "cico:xjz", member_of_collection_ids: collection.id)
        described_class.perform_now(collection_id: collection.id, logger: logger)
        expect(query_service.find_by(id: resource.id).local_identifier).to eq ["dcl:1pt"]
        expect(query_service.find_by(id: resource2.id).local_identifier).to eq ["dcl:xjz"]
        expect(logger).to have_received(:info).twice
      end
    end

    context "when local_identifier doesn't start with `cico:`" do
      it "does not update" do
        resource = FactoryBot.create_for_repository(:scanned_resource, local_identifier: "dcl:1pt", member_of_collection_ids: collection.id)
        described_class.perform_now(collection_id: collection.id, logger: logger)
        expect(query_service.find_by(id: resource.id).local_identifier).to eq ["dcl:1pt"]
        expect(logger).not_to have_received(:info)
      end
    end

    context "when a resource has multiple local_identifiers" do
      it "updates just the cico: one" do
        resource = FactoryBot.create_for_repository(:scanned_resource, local_identifier: ["cico:1pt", "an_ark_or_something"], member_of_collection_ids: collection.id)
        described_class.perform_now(collection_id: collection.id, logger: logger)
        expect(query_service.find_by(id: resource.id).local_identifier).to contain_exactly("dcl:1pt", "an_ark_or_something")
      end
    end
  end
end
