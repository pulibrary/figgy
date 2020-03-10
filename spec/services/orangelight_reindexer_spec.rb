# frozen_string_literal: true
require "rails_helper"

RSpec.describe OrangelightReindexer do
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

  describe "#reindex_orangelight" do
    let(:messenger) { instance_double(EventGenerator) }
    let(:resource) do
      FactoryBot.create_for_repository(
        :coin,
        title: "Coin: 1474",
        state: "complete",
        identifier: "ark:/99999/fk4"
      )
    end

    before do
      change_set_persister.save(change_set: DynamicChangeSet.new(resource))
      allow(EventGenerator).to receive(:new).and_return(messenger)
      allow(messenger).to receive(:record_updated)
    end

    context "with a valid orangelight resource" do
      it "sends an updated record message" do
        described_class.reindex_orangelight(logger: logger)
        expect(messenger).to have_received(:record_updated)
      end
    end

    context "with a resource that throws an exception" do
      before do
        allow(EventGenerator).to receive(:new).and_raise("error")
      end

      it "does not send an updated record message" do
        described_class.reindex_orangelight(logger: logger)
        expect(messenger).not_to have_received(:record_updated)
        expect(logger).to have_received(:warn)
      end
    end
  end
end
