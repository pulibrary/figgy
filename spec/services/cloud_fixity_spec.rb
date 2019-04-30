# frozen_string_literal: true
require "rails_helper"

RSpec.describe CloudFixity do
  let(:pubsub) { instance_double(Google::Cloud::Pubsub::Project) }
  let(:topic) { instance_double(Google::Cloud::Pubsub::Topic) }
  let(:subscription) { instance_double(Google::Cloud::Pubsub::Subscription) }
  let(:message) { instance_double(Google::Cloud::Pubsub::ReceivedMessage) }
  let(:batch_publisher) { instance_double(Google::Cloud::PubSub::BatchPublisher) }
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
    allow(topic).to receive(:publish).and_yield(batch_publisher)
    allow(batch_publisher).to receive(:publish)
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
    it "handles a SignalException" do
      allow(UpdateFixityJob).to receive(:perform_later).with(anything).and_raise(SignalException, "TERM")
      expect { CloudFixity::Worker.run! }.not_to raise_exception
    end
  end

  describe ".queue_random!" do
    it "queues a random percent of the total" do
      id = SecureRandom.uuid
      id2 = SecureRandom.uuid
      resources = Array.new(10) do |_n|
        FactoryBot.create_for_repository(
          :preservation_object,
          metadata_node: FileMetadata.new(
            id: id,
            file_identifiers: Valkyrie::ID.new("shrine://get/to/thechoppa.tif"),
            checksum: MultiChecksum.new(md5: "5")
          ),
          binary_nodes: [
            FileMetadata.new(
              id: id2,
              file_identifiers: Valkyrie::ID.new("shrine://ill/be/back.tif"),
              checksum: MultiChecksum.new(md5: "5")
            )
          ]
        )
      end
      allow(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to receive(:find_random_resources_by_model).and_return([resources[0]].lazy)

      CloudFixity::FixityRequestor.queue_random!(percent: 10)

      expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to have_received(:find_random_resources_by_model).with(limit: 1, model: PreservationObject)
      expect(pubsub).to have_received(:topic).with("figgy-staging-fixity-request")
      expect(batch_publisher).to have_received(:publish).exactly(2).times
      expect(batch_publisher).to have_received(:publish).with(
        {
          md5: "5",
          cloudPath: "get/to/thechoppa.tif",
          preservation_object_id: resources[0].id.to_s,
          file_metadata_node_id: id,
          child_property: "metadata_node"
        }.to_json
      )
    end
  end
end
