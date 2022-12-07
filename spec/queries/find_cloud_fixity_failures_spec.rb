# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindCloudFixityFailures do
  with_queue_adapter :inline
  subject(:query) { described_class.new(query_service: query_service) }

  let(:metadata_adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { metadata_adapter.query_service }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: metadata_adapter, storage_adapter: storage_adapter) }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:file) { fixture_file_upload("files/example.tif", "image/tiff") }
  let(:resource) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
  let(:resource2) { FactoryBot.create_for_repository(:complete_scanned_resource, files: [file]) }
  let(:preservation_object) do
    Wayfinder.for(resource).preservation_objects.first
  end
  let(:preservation_object2) do
    Wayfinder.for(resource2).preservation_objects.first
  end
  let(:file_set) { resource.decorate.file_sets.first }
  let(:file_set2) { resource2.decorate.file_sets.first }
  let(:child_id) { preservation_object.metadata_node.id }
  let(:child_id2) { preservation_object2.metadata_node.id }
  let(:child_property) { "metadata_node" }
  let(:event) { FactoryBot.create_for_repository(:cloud_fixity_event, status: "FAILURE", resource_id: preservation_object.id, child_id: child_id, child_property: child_property) }
  let(:event2) { FactoryBot.create_for_repository(:cloud_fixity_event, status: "FAILURE", resource_id: preservation_object2.id, child_id: child_id2, child_property: child_property, current: true) }
  let(:event3) { FactoryBot.create_for_repository(:cloud_fixity_event, status: "FAILURE", resource_id: preservation_object.id, child_id: child_id, child_property: child_property, current: true) }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    event
    event2
    event3
  end

  describe "#find_cloud_fixity_failures" do
    it "retrieves the last Events for the failed fixity checks" do
      output = query.find_cloud_fixity_failures
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include event3.id
      expect(output_ids).to include event2.id
    end

    context "when a fixity check which has failed later succeeds" do
      let(:event3) { FactoryBot.create_for_repository(:event, status: "FAILURE", resource_id: preservation_object.id, child_id: child_id, child_property: child_property) }
      let(:event4) { FactoryBot.create_for_repository(:event, status: "SUCCESS", resource_id: preservation_object.id, child_id: child_id, child_property: child_property, current: true) }

      it "does not retrieve the Event for the failure" do
        event4
        output = query.find_cloud_fixity_failures
        expect(output.length).to eq 1
        output_ids = output.map(&:id)
        expect(output_ids).to include event2.id
      end
    end
  end
end
