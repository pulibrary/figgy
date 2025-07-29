# frozen_string_literal: true
require "rails_helper"

RSpec.describe ServerUploadJob do
  with_queue_adapter :inline
  context "when a resource is gone" do
    it "returns false and doesn't error" do
      pending_upload = PendingUpload.new(
        id: SecureRandom.uuid,
        storage_adapter_id: "disk://#{Figgy.config['ingest_folder_path']}/examples/bulk_ingest/991234563506421/vol1/color.tif"
      )
      expect { described_class.perform_now(SecureRandom.uuid, [pending_upload.id.to_s]) }.not_to raise_error
    end
  end
  context "when given a resource and pending upload IDs" do
    it "creates and appends them" do
      pending_upload = PendingUpload.new(
        id: SecureRandom.uuid,
        storage_adapter_id: "disk://#{Figgy.config['ingest_folder_path']}/examples/bulk_ingest/991234563506421/vol1/color.tif"
      )
      resource = FactoryBot.create_for_repository(:scanned_resource, pending_uploads: [pending_upload])
      propagated_resources = []
      # Need to make sure it doesn't repeatedly propagate visibility/state, but
      # the arguments are complex so keep track of them with a mock.
      allow(ChangeSetPersister::PropagateVisibilityAndState).to receive(:new) do |args|
        propagated_resources << args[:change_set].resource
        instance_double(ChangeSetPersister::PropagateVisibilityAndState, run: true)
      end

      described_class.perform_now(resource.id.to_s, [pending_upload.id.to_s])
      reloaded_resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)

      # Make sure a FileSet was created.
      expect(reloaded_resource.member_ids.length).to eq 1
      # Ensure pending_uploads is cleared from the resource.
      expect(reloaded_resource.pending_uploads).to be_blank
      # Ensure visibility didn't propagate - it's expensive and unneeded for
      # FileSets.
      expect(propagated_resources.map(&:id)).not_to include(resource.id)
    end
  end

  context "when the resource is so big the database transaction expires" do
    it "does not retry" do
      pending_upload = PendingUpload.new(
        id: SecureRandom.uuid,
        storage_adapter_id: "disk://#{Figgy.config['ingest_folder_path']}/examples/bulk_ingest/991234563506421/vol1/color.tif"
      )
      resource = FactoryBot.create_for_repository(:scanned_resource, pending_uploads: [pending_upload])

      buffered_csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(buffered_csp_mock).to receive(:save).and_raise(Sequel::DatabaseDisconnectError)
      allow(buffered_csp_mock).to receive(:prevent_propagation!)
      allow(buffered_csp_mock).to receive(:query_service).and_return(ChangeSetPersister.default.query_service)
      csp_mock = instance_double(ChangeSetPersister::Basic)
      allow(csp_mock).to receive(:buffer_into_index).and_yield(buffered_csp_mock)
      allow_any_instance_of(described_class).to receive(:change_set_persister).and_return(csp_mock)
      allow(Honeybadger).to receive(:notify)

      expect { described_class.perform_now(resource.id.to_s, [pending_upload.id.to_s]) }.not_to raise_error(Sequel::DatabaseDisconnectError)
      expect(Honeybadger).to have_received(:notify)
    end
  end
end
