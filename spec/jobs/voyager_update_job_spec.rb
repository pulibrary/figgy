
# frozen_string_literal: true
require "rails_helper"

describe VoyagerUpdateJob do
  with_queue_adapter :inline

  let(:ids) { resources.map(&:id) }

  before do
    stub_bibdata(bib_id: "123456")
    stub_bibdata(bib_id: "4609321")
  end
  let(:resources) do
    [
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456"),
      FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "4609321")
    ]
  end

  describe "#perform" do
    let(:buffered_change_set_persister) { instance_double(ChangeSetPersister::Basic) }

    before do
      resources
      allow(buffered_change_set_persister).to receive(:save)
      allow_any_instance_of(ChangeSetPersister::Basic).to receive(:buffer_into_index).and_yield(buffered_change_set_persister)
      described_class.perform_now(ids)
    end

    it "queries for all resources and updates them asynchronously" do
      expect(buffered_change_set_persister).to have_received(:save).exactly(2).times
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
      expect { described_class.perform_now(["3"]) }.to output("VoyagerUpdateJob: Unable to process the changed Voyager record 3: Valkyrie::Persistence::ObjectNotFoundError\n").to_stderr
    end
  end
end
