# frozen_string_literal: true
require "rails_helper"

RSpec.describe ServerUploadJob do
  with_queue_adapter :inline
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
end
