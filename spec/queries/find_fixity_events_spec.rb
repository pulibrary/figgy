# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindFixityEvents do
  with_queue_adapter :inline
  subject(:query) { described_class.new(query_service: query_service) }

  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:event_resource_id) { Valkyrie::ID.new(SecureRandom.uuid) }
  let(:event) { FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: event_resource_id, current: true) }
  let(:event2_resource_id) { Valkyrie::ID.new(SecureRandom.uuid) }
  let(:event2) { FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: event2_resource_id, current: true) }
  let(:local_event) { FactoryBot.create_for_repository(:local_fixity_success, current: true) }

  before do
    event
    event2
    local_event
  end

  describe "#find_fixity_events" do
    let(:status) { "SUCCESS" }

    it "can find file_sets for files stored in cloud services with successful fixity checks" do
      output = query.find_fixity_events(status: status, type: :cloud_fixity)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include event.id
      expect(output_ids).to include event2.id
      output_type = output.map(&:type).uniq
      expect(output_type).to eq ["cloud_fixity"]
    end

    # Note it can do this but it will only find Events; it won't fall back to
    # the fixity checks that were run before local fixity used Events.
    it "can find events for successful local fixity checks" do
      output = query.find_fixity_events(status: status, type: :local_fixity)
      expect(output.length).to eq 1
      expect(output.first.type).to eq "local_fixity"
    end

    context "when querying for failed fixity checks" do
      let(:status) { "FAILURE" }
      let(:event2) { FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: event2_resource_id) }
      let(:event3_resource_id) { Valkyrie::ID.new(SecureRandom.uuid) }
      let(:event3) { FactoryBot.create_for_repository(:cloud_fixity_event, status: status, resource_id: event3_resource_id, current: true) }

      before do
        event3
      end

      it "can find file_sets for files stored in cloud services with failed fixity checks" do
        output = query.find_fixity_events(status: status, type: :cloud_fixity)
        expect(output.length).to eq 1
        output_ids = output.map(&:id)
        expect(output_ids).to include event3.id
      end
    end

    context "when a fixity check which has failed later succeeds" do
      let(:event) { FactoryBot.create_for_repository(:cloud_fixity_event, status:  "FAILURE", resource_id: event_resource_id, current: false) }
      let(:event2) { FactoryBot.create_for_repository(:cloud_fixity_event, status: "SUCCESS", resource_id: event_resource_id, current: true) }
      let(:event3_resource_id) { Valkyrie::ID.new(SecureRandom.uuid) }
      let(:event3) { FactoryBot.create_for_repository(:cloud_fixity_event, status: "FAILURE", resource_id: event3_resource_id, current: true) }

      before do
        event3
      end

      it "does not retrieve the Event for the failure" do
        output = query.find_fixity_events(status: "FAILURE", type: :cloud_fixity)
        expect(output.length).to eq 1
        output_ids = output.map(&:id)
        expect(output_ids).to include event3.id
      end
    end

    it "limits the number of results" do
      5.times do
        FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: Valkyrie::ID.new(SecureRandom.uuid), current: true)
      end

      output = query.find_fixity_events(limit: 2, status: status, type: :cloud_fixity)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include event.id
      expect(output_ids).to include event2.id
    end

    it "sorts by either ascending or descending order" do
      output = query.find_fixity_events(status: status, type: :cloud_fixity)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event.id
      expect(output.last.id).to eq event2.id

      output = query.find_fixity_events(sort: "DESC", status: status, type: :cloud_fixity)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event2.id
      expect(output.last.id).to eq event.id
    end

    it "sorts by either the time of the last update or the resource creation" do
      output = query.find_fixity_events(order_by_property: "created_at", status: status, type: :cloud_fixity)
      expect(output.length).to eq 2
      expect(output.first.id).to eq event.id
      expect(output.last.id).to eq event2.id

      cs = EventChangeSet.new(event2)
      cs.validate(message: "updated")
      change_set_persister.save(change_set: cs)

      output2 = query.find_fixity_events(sort: "DESC", status: status, type: :cloud_fixity)
      expect(output2.length).to eq 2
      expect(output2.first.id).to eq event2.id
      expect(output2.last.id).to eq event.id
    end

    context "when resource_id has more than one event" do
      let(:event) { FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: event_resource_id, current: false) }
      let(:event2) { FactoryBot.create_for_repository(:cloud_fixity_event, resource_id: event_resource_id, current: true) }

      it "returns only the current event" do
        output = query.find_fixity_events(status: status, type: :cloud_fixity)
        expect(output.length).to eq 1
        output_id = output.map(&:id).first
        expect(output_id).to eq event2.id
      end
    end
  end
end
