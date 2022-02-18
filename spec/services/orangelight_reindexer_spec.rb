# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrangelightReindexer do
  let(:logger) { instance_double(Logger, info: nil, warn: nil) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: Valkyrie.config.storage_adapter) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }
  let(:parent_issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [resource.id]) }
  let(:resource) do
    FactoryBot.create_for_repository(
      :coin,
      title: "Coin: 1474",
      state: "complete",
      identifier: "ark:/99999/fk4"
    )
  end

  before do
    change_set_persister.save(change_set: ChangeSet.for(resource))
    change_set_persister.save(change_set: ChangeSet.for(parent_issue))
  end

  after do
    ENV["BULK"] = nil
  end

  describe "#reindex_orangelight" do
    context "with a valid orangelight resource" do
      let(:orangelight_event_generator) { EventGenerator::OrangelightEventGenerator.new(rabbit_connection) }
      let(:rabbit_connection) { instance_double(OrangelightMessagingClient, publish: true) }
      before do
        allow(EventGenerator::OrangelightEventGenerator).to receive(:new).and_return(orangelight_event_generator)
        allow(orangelight_event_generator).to receive(:record_updated).and_call_original
      end

      it "sends an updated record message" do
        orangelight_doc = OrangelightDocument.new(resource).to_h
        expected_result = {
          "id" => resource.id.to_s,
          "event" => "UPDATED",
          "bulk" => "true",
          "doc" => orangelight_doc
        }
        described_class.reindex_orangelight(logger: logger)
        expect(rabbit_connection).to have_received(:publish).with(expected_result.to_json)
      end
    end

    context "with a resource that throws an exception" do
      let(:messenger) { instance_double(EventGenerator) }
      before do
        allow(messenger).to receive(:record_updated)
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
