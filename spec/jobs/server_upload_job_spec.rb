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

      described_class.perform_now(resource.id.to_s, [pending_upload.id.to_s])
      reloaded_resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)

      expect(reloaded_resource.member_ids.length).to eq 1
      expect(reloaded_resource.pending_uploads).to be_blank
    end
  end
end
