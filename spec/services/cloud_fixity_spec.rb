# frozen_string_literal: true
require "rails_helper"

RSpec.describe CloudFixity do
  with_queue_adapter :inline

  let(:pubsub) { instance_double(Google::Cloud::Pubsub::Project) }
  let(:topic) { instance_double(Google::Cloud::Pubsub::Topic) }
  let(:subscription) { instance_double(Google::Cloud::Pubsub::Subscription) }
  let(:message) { instance_double(Google::Cloud::Pubsub::ReceivedMessage) }
  let(:batch_publisher) { instance_double(Google::Cloud::PubSub::BatchPublisher) }
  let(:json) do
    {
      status: "SUCCESS",
      resource_id: SecureRandom.uuid,
      child_id: "1",
      child_property: :metadata_node
    }.to_json
  end
  let(:subscriber) { instance_double(Google::Cloud::Pubsub::Subscriber) }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }

  before do
    # Needed to prevent pubsub double from leaking into other examples
    described_class.instance_variable_set(:@pubsub, nil)
    described_class::FixityRequestor.instance_variable_set(:@pubsub, nil)

    stub_ezid(shoulder: shoulder, blade: blade)
    allow(Google::Cloud::Pubsub).to receive(:new).and_return(pubsub)
    allow(pubsub).to receive(:topic).and_return(topic)
    allow(topic).to receive(:subscription).and_return(subscription)
    allow(topic).to receive(:publish).and_yield(batch_publisher)
    allow(batch_publisher).to receive(:publish)
    allow(message).to receive(:data).and_return(json)
    allow(message).to receive(:acknowledge!)
    allow(subscriber).to receive(:start)
    allow(subscription).to receive(:listen).and_yield(message).and_return(subscriber)
    allow_any_instance_of(CloudFixity::Worker).to receive(:sleep)
  end

  describe ".run!" do
    before do
      CloudFixity::Worker.run!
    end

    context "with a resource preserved in a cloud service" do
      let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
      let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
      let(:resource) { Wayfinder.for(scanned_resource).preservation_objects.first }
      let(:file_metadata) { resource.metadata_node }
      let(:json) do
        {
          status: "SUCCESS",
          resource_id: resource.id.to_s,
          child_id: file_metadata.id.to_s,
          child_property: :metadata_node
        }.to_json
      end

      it "generates Events in response to messages published with the subscribes to the figgy-staging-fixity-status topic" do
        expect(pubsub).to have_received(:topic).with("figgy-staging-fixity-status")
        expect(topic).to have_received(:subscription).with("figgy-staging-fixity-status")

        cloud_event = query_service.custom_queries.find_fixity_events(status: "SUCCESS", type: :cloud_fixity)
        expect(cloud_event).not_to be_empty
        persisted_event = cloud_event.first
        expect(persisted_event.resource_id).to eq resource.id
        expect(persisted_event.child_property).to eq "metadata_node"
        expect(persisted_event.child_id).to eq file_metadata.id
      end
    end
    it "handles a SignalException" do
      allow(CloudFixityJob).to receive(:perform_later).with(anything).and_raise(SignalException, "TERM")
      expect { CloudFixity::Worker.run! }.not_to raise_exception
    end
  end

  describe ".queue_daily_check!" do
    it "queues a random per-day subset given an annual percent to check" do
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
      allow(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to receive(:count_all_of_model).with(model: PreservationObject).and_return(10_000)
      allow(Rails.logger).to receive(:info)

      CloudFixity::FixityRequestor.queue_daily_check!(annual_percent: 10)

      expect(Valkyrie::MetadataAdapter.find(:postgres).query_service.custom_queries).to have_received(:find_random_resources_by_model).with(limit: 3, model: PreservationObject)
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
      expect(Rails.logger).to have_received(:info).with("Enqueued 3 PreservationObjects for Cloud Fixity Checking")
    end
  end

  describe ".queue_resource_check!" do
    it "queues a single resource to check" do
      id = SecureRandom.uuid
      id2 = SecureRandom.uuid
      resource = FactoryBot.create_for_repository(:scanned_resource)
      preservation_object = FactoryBot.create_for_repository(
                                :preservation_object,
                                preserved_object_id: resource.id,
                                metadata_node: FileMetadata.new(
                                  id: id,
                                  file_identifiers: Valkyrie::ID.new("shrine://yippie/ki/yay.tif"),
                                  checksum: MultiChecksum.new(md5: "5")
                                ),
                                binary_nodes: [
                                  FileMetadata.new(
                                    id: id2,
                                    file_identifiers: Valkyrie::ID.new("shrine://nakatomi/tower.tif"),
                                    checksum: MultiChecksum.new(md5: "5")
                                  )
                                ]
                              )

      allow(Rails.logger).to receive(:info)

      CloudFixity::FixityRequestor.queue_resource_check!(id: resource.id.to_s)

      expect(pubsub).to have_received(:topic).with("figgy-staging-fixity-request")
      expect(batch_publisher).to have_received(:publish).exactly(2).times
      expect(batch_publisher).to have_received(:publish).with(
        {
          md5: "5",
          cloudPath: "yippie/ki/yay.tif",
          preservation_object_id: preservation_object.id.to_s,
          file_metadata_node_id: id,
          child_property: "metadata_node"
        }.to_json
      )
      expect(Rails.logger).to have_received(:info).with("Enqueued PreservationObject #{preservation_object.id} for Cloud Fixity Checking")
    end
  end
end
