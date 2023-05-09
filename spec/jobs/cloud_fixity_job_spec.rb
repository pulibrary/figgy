# frozen_string_literal: true
require "rails_helper"

RSpec.describe CloudFixityJob do
  describe ".perform" do
    let(:file_set) { FactoryBot.create_for_repository(:file_set) }
    let(:resource) { FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, metadata_node: FileMetadata.new(id: SecureRandom.uuid)) }

    it "creates a new fixity event and marks the previously current event no longer current" do
      old_event = FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: resource.metadata_node.id, child_property: "metadata_node", current: true)
      described_class.perform_now(status: "SUCCESS", resource_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")

      events = query_service.find_all_of_model(model: Event)
      expect(events.to_a.length).to eq 2
      old_event = events.find { |e| e.id == old_event.id }
      new_event = events.reject { |e| e.id == old_event.id }.first
      expect(new_event.type).to eq "cloud_fixity"
      expect(new_event.resource_id).to eq resource.id
      expect(new_event.child_id).to eq resource.metadata_node.id
      expect(new_event.child_property).to eq "metadata_node"
      expect(new_event.current).to be true
      expect(old_event.current).to be false
    end

    context "when status is FAILURE" do
      before do
        allow(Honeybadger).to receive(:notify)
        allow(RepairCloudFixityJob).to receive(:perform_later)
      end

      context "and previous event was repairing" do
        it "creates a failure event and notifies honeybadger" do
          FactoryBot.create_for_repository(:cloud_fixity_event, status: Event::REPAIRING, resource_id: resource.id, child_id: resource.metadata_node.id, child_property: "metadata_node", current: true)
          described_class.perform_now(status: "FAILURE", resource_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 1
          event = current_events.first
          expect(event).to be_failed
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).not_to have_received(:perform_later)
        end
      end

      context "and previous event was not repairing" do
        it "creates a repairing event, kicks off repair job, and notifies honeybadger" do
          FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: resource.id, child_id: resource.metadata_node.id, child_property: "metadata_node", current: true)
          described_class.perform_now(status: "FAILURE", resource_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 1
          event = current_events.first
          expect(event).to be_repairing
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).to have_received(:perform_later)
        end
      end

      context "and there was no previous event" do
        it "creates a repairing event, kicks off repair job, and notifies honeybadger" do
          described_class.perform_now(status: "FAILURE", resource_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
          events = query_service.find_all_of_model(model: Event)
          current_events = events.select(&:current?)
          expect(current_events.to_a.length).to eq 1
          event = current_events.first
          expect(event).to be_repairing
          expect(Honeybadger).to have_received(:notify)
          expect(RepairCloudFixityJob).to have_received(:perform_later)
        end
      end
    end

    context "when resource does not exist" do
      before do
        allow(Honeybadger).to receive(:notify)
      end
      it "exits quietly" do
        described_class.perform_now(status: "FAILURE", resource_id: "oldresourceid", child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")
        expect(Honeybadger).not_to have_received(:notify)
      end
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
