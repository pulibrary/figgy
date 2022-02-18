# frozen_string_literal: true

require "rails_helper"

describe VoyagerUpdater::EventStream do
  subject(:event_stream) { described_class.new(url) }
  let(:url) { "http://localhost.localdomain" }
  let(:id) { "1234567" }
  let(:dump_url) { "http://localhost.localdomain" }
  let(:dump_type) { "CHANGED_RECORDS" }
  let(:data) do
    [
      {
        "id" => id,
        "dump_url" => dump_url,
        "dump_type" => dump_type
      }
    ]
  end

  before do
    stub_request(:get, "http://localhost.localdomain/").to_return(body: data.to_json)
  end

  describe ".new" do
    it "constructs the object for handling streams of events" do
      expect(event_stream.url).to eq(url)
    end
  end

  describe "#events" do
    it "constructs Event objects using the Voyager update data" do
      expect(event_stream.events).not_to be_empty
      received_events = event_stream.events
      event_ids = received_events.map(&:id)
      expect(event_ids.map(&:to_s)).to include id
      expect(received_events.map(&:class)).to include VoyagerUpdater::Event
    end
  end

  describe "#process!" do
    let(:event) { instance_double(VoyagerUpdater::Event) }
    before do
      allow(event).to receive(:process!)
      allow(VoyagerUpdater::Event).to receive(:new).and_return(event)
      event_stream.process!
    end
    it "processes each event" do
      expect(event).to have_received(:process!)
    end
  end
end
