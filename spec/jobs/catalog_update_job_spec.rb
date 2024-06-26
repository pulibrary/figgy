
# frozen_string_literal: true
require "rails_helper"

describe CatalogUpdateJob do
  with_queue_adapter :inline

  let(:ids) { resources.map(&:id) }

  before do
    stub_catalog(bib_id: "991234563506421")
    stub_catalog(bib_id: "9946093213506421")
  end
  let(:resources) do
    [
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "991234563506421"),
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "9946093213506421")
    ]
  end

  describe "#perform" do
    let(:buffered_change_set_persister) { instance_double(ChangeSetPersister::Basic) }

    before do
      resources
      described_class.perform_now(ids)
    end

    it "queries for all resources and updates them asynchronously" do
      resource1 = find_resource(resources.first.id)
      resource2 = find_resource(resources.last.id)
      expect(resource1.title.first.to_s).to eq("Earth rites : fertility rites in pre-industrial Britain / Janet and Colin Bord.")
      expect(resource2.title.first.to_s).to eq("Bible, Latin.")
    end
  end

  context "when given invalid IDs" do
    let(:logger) { instance_double(ActiveSupport::Logger) }
    let(:resource) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: resources.first.source_metadata_identifier) }
    let(:buffered_change_set_persister) { instance_double(ChangeSetPersister::Basic) }

    before do
      resource
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(Rails).to receive(:logger).and_return(logger)
    end

    it "logs a warning" do
      expect { described_class.perform_now(["3"]) }.to output("CatalogUpdateJob: Unable to process the changed Catalog record 3: Valkyrie::Persistence::ObjectNotFoundError\n").to_stderr
    end
  end

  def find_resource(id)
    Valkyrie.config.metadata_adapter.query_service.find_by(id: id)
  end
end
