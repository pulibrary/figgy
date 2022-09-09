
# frozen_string_literal: true
require "rails_helper"

describe VoyagerUpdater::Event do
  subject(:event) { described_class.new(values) }
  let(:id) { 123_456 }
  let(:dump_url) { "http://example.com" }
  let(:dump_type) { "CHANGED_RECORDS" }
  let(:values) do
    {
      "id" => id,
      "dump_url" => dump_url,
      "dump_type" => dump_type
    }
  end
  let(:dump_data) do
    {
      "ids" => {
        "update_ids" => ["123456", "4609321"]
      }
    }
  end

  describe ".new" do
    it "constructs the Event with a Hash" do
      expect(event.id).to eq(1_234_56)
      expect(event.dump_url).to eq(dump_url)
      expect(event.dump_type).to eq(dump_type)
    end
  end

  describe "#processed?" do
    context "with an existing processed event" do
      before do
        FactoryBot.create_for_repository(:processed_event, event_id: id)
      end
      it "determines if a processing job has been enqueued" do
        expect(event.processed?).to be true
      end
    end

    it "determines if a processing job has been enqueued" do
      expect(event.processed?).to be false
    end
  end

  describe "#dump" do
    it "constructs the data dump object" do
      expect(event.dump).to be_a VoyagerUpdater::Dump
    end
  end

  describe "#unprocessable?" do
    it "allows supported data dump types to be processed" do
      expect(event.unprocessable?).to be false
    end

    context "when the data dump type is unsupported" do
      let(:dump_type) { "INVALID" }

      it "does not allow the data dump to be processed" do
        expect(event.unprocessable?).to be true
      end
    end
  end

  describe "#process!" do
    let(:resource1) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "123456") }
    let(:resource2) { FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "4609321") }

    before do
      allow(VoyagerUpdateJob).to receive(:perform_later)
      stub_catalog(bib_id: "123456")
      stub_catalog(bib_id: "4609321")
      resource1
      resource2
      stub_request(:get, dump_url).to_return(body: dump_data.to_json)

      event.process!
    end

    it "enqueues an ActiveJob for updating resources with changed records in Voyager" do
      expect(VoyagerUpdateJob).to have_received(:perform_later).with([resource1.id.to_s, resource2.id.to_s])
    end
  end

  context "when the Voyager data dump is not processable" do
    let(:dump_type) { "INVALID" }

    before do
      allow(VoyagerUpdateJob).to receive(:perform_later)
      event.process!
    end

    describe "#process!" do
      it "does not enqueue the job" do
        expect(VoyagerUpdateJob).not_to have_received(:perform_later)
      end
    end
  end

  context "when the job has been processed" do
    describe "#process!" do
      before do
        FactoryBot.create_for_repository(:processed_event, event_id: id)
        allow(VoyagerUpdateJob).to receive(:perform_later)

        event.process!
      end

      it "does not enqueue the job" do
        expect(VoyagerUpdateJob).not_to have_received(:perform_later)
      end
    end
  end
end
