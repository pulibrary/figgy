# frozen_string_literal: true
require "rails_helper"

RSpec.describe CloudFixity do
  let(:pubsub) { instance_double(Google::Cloud::Pubsub::Project) }
  let(:topic) { instance_double(Google::Cloud::Pubsub::Topic) }
  let(:subscription) { instance_double(Google::Cloud::Pubsub::Subscription) }
  let(:message) { instance_double(Google::Cloud::Pubsub::ReceivedMessage) }
  let(:json) do
    {
      status: "SUCCESS",
      resource_id: "1",
      child_id: "1",
      child_property: :metadata_node
    }.to_json
  end
  let(:subscriber) { instance_double(Google::Cloud::Pubsub::Subscriber) }
  before do
    allow(Google::Cloud::Pubsub).to receive(:new).and_return(pubsub)
    allow(pubsub).to receive(:topic).and_return(topic)
    allow(topic).to receive(:subscription).and_return(subscription)
    allow(message).to receive(:data).and_return(json)
    allow(message).to receive(:acknowledge!)
    allow(subscriber).to receive(:start)
    allow(subscription).to receive(:listen).and_yield(message).and_return(subscriber)
    allow(CloudFixity::Worker).to receive(:sleep)
  end
  describe ".run!" do
    it "works" do
      allow(UpdateFixityJob).to receive(:perform_later)
      CloudFixity::Worker.run!
      expect(UpdateFixityJob).to have_received(:perform_later).with(status: "SUCCESS", resource_id: "1", child_id: "1", child_property: "metadata_node")
      expect(pubsub).to have_received(:topic).with("figgy-staging-fixity-status")
      expect(topic).to have_received(:subscription).with("figgy-staging-fixity-status")
    end
  end
end
