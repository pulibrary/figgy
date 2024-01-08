# frozen_string_literal: true
require "rails_helper"

RSpec.describe CloudFixityJob do
  with_queue_adapter :inline
  describe ".perform" do
    let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
    let(:parent_resource) do
      r = FactoryBot.create_for_repository(:scanned_resource, files: [file])
      r = query_service.find_by(id: r.id)
      change_set = ChangeSet.for(r)
      change_set.state = "complete"
      ChangeSetPersister.default.save(change_set: change_set)
    end
    let(:file_set) { Wayfinder.for(parent_resource).members.first }
    let(:resource) do
      Wayfinder.for(file_set).preservation_object
    end

    before do
      stub_ezid
      resource
      allow(RepairCloudFixityJob).to receive(:perform_later)
      events = query_service.find_all_of_model(model: Event)
      # Delete local fixity event.
      ChangeSetPersister.default.persister.delete(resource: events.first) if events.present?
    end

    it "creates a new fixity event and marks the previously current event no longer current" do
      # The old event will have a different child_id, because a new node is made
      # when it's preserved.
      old_event = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: SecureRandom.uuid, child_property: "metadata_node", current: true)
      described_class.perform_now(status: "SUCCESS", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")

      events = query_service.find_all_of_model(model: Event)
      expect(events.to_a.length).to eq 2
      old_event = events.find { |e| e.id == old_event.id }
      new_event = events.reject { |e| e.id == old_event.id }.last
      expect(new_event.type).to eq "cloud_fixity"
      expect(new_event.resource_id).to eq resource.id
      expect(new_event.child_id).to eq resource.metadata_node.id
      expect(new_event.child_property).to eq "metadata_node"
      expect(new_event.current).to be true
      expect(old_event.current).to be false
    end

    context "when the metadata version and the preserved object lock token don't match" do
      before do
        resource.metadata_version = "invalid-token"
        ChangeSetPersister.default.persister.save(resource: resource)
        allow(Honeybadger).to receive(:notify)
        allow(RepairCloudFixityJob).to receive(:perform_later)
      end

      it "creates a repairing event and kicks off repair job" do
        old_event = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: SecureRandom.uuid, child_property: "metadata_node", current: true)
        described_class.perform_now(status: "SUCCESS", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
        events = query_service.find_all_of_model(model: Event)
        old_event = events.find { |e| e.id == old_event.id }
        new_event = events.reject { |e| e.id == old_event.id }.first
        expect(new_event).to be_repairing
        expect(RepairCloudFixityJob).to have_received(:perform_later).with(event_id: new_event.id.to_s)
      end

      context "but the resource should no longer be preserved" do
        it "doesn't try to repair it" do
          FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: SecureRandom.uuid, child_property: "metadata_node", current: true)
          # Delete the parent so it's no longer preserved.
          ChangeSetPersister.default.persister.delete(resource: parent_resource)

          described_class.perform_now(status: "SUCCESS", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")

          expect(RepairCloudFixityJob).not_to have_received(:perform_later)
        end
      end
    end

    context "when the preserved object lock token is nil" do
      it "passes no matter the metadata_version" do
        old_event = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: SecureRandom.uuid, child_property: "metadata_node", current: true)
        allow_any_instance_of(FileSet).to receive(:optimistic_lock_token).and_return([])

        described_class.perform_now(status: "SUCCESS", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")

        events = query_service.find_all_of_model(model: Event)
        old_event = events.find { |e| e.id == old_event.id }
        new_event = events.reject { |e| e.id == old_event.id }.first
        expect(new_event).to be_successful
      end
    end

    context "when status is FAILURE" do
      before do
        allow(Honeybadger).to receive(:notify)
        allow(RepairCloudFixityJob).to receive(:perform_later)
      end

      context "and previous event was repairing" do
        it "creates a failure event and notifies honeybadger" do
          FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: resource.id, child_id: resource.metadata_node.id, child_property: "metadata_node", current: true)
          described_class.perform_now(status: "FAILURE", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 1
          event = current_events.first
          expect(event).to be_failed
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).not_to have_received(:perform_later).with(event_id: event.id)
        end
      end

      # tests that we get the right event when there's also one for the binary node
      context "and previous event was not repairing" do
        it "creates a repairing event, kicks off repair job, and notifies honeybadger" do
          FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: Valkyrie::ID.new(SecureRandom.uuid), child_property: "binary_node", current: true)
          FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: resource.metadata_node.id, child_property: "metadata_node", current: true)
          described_class.perform_now(status: "FAILURE", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 2
          event = current_events.find { |e| e.child_id == resource.metadata_node.id }
          expect(event).to be_repairing
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).to have_received(:perform_later).with(event_id: event.id.to_s)
        end
      end

      context "and there was no previous event" do
        it "creates a repairing event, kicks off repair job, and notifies honeybadger" do
          described_class.perform_now(status: "FAILURE", preservation_object_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 1
          event = current_events.first
          expect(event).to be_repairing
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).to have_received(:perform_later).with(event_id: event.id.to_s)
        end
      end
    end

    context "when resource does not exist" do
      before do
        allow(Honeybadger).to receive(:notify)
      end
      it "exits quietly" do
        described_class.perform_now(status: "FAILURE", preservation_object_id: "oldresourceid", child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
        expect(Honeybadger).not_to have_received(:notify)
      end
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
