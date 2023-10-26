# frozen_string_literal: true
require "rails_helper"

RSpec.describe Migrations::MetadataRepreserver do
  with_queue_adapter :inline
  before do
    stub_ezid
  end
  describe ".run!" do
    context "when there are preserved resources that don't have a metadata_version" do
      it "sets their metadata_version and uploads a new file" do
        po = create_preservation_object_with_no_metadata_version

        described_class.run!

        reloaded_po = ChangeSetPersister.default.query_service.find_by(id: po.id)
        expect(reloaded_po.metadata_version).not_to be_nil
      end
    end
    context "when there are preserved resources that don't have a lock token" do
      it "generates one and then sets a metadata_version" do
        resource = create_resource_no_lock_token
        expect(resource.optimistic_lock_token).to be_empty

        described_class.run!

        reloaded_resource = ChangeSetPersister.default.query_service.find_by(id: resource.id)
        expect(reloaded_resource.optimistic_lock_token).not_to be_empty
      end
    end
  end

  def create_preservation_object_with_no_metadata_version
    preserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource, run_callbacks: true)
    po = Wayfinder.for(preserved_resource).preservation_object
    po.metadata_version = nil
    ChangeSetPersister.default.metadata_adapter.persister.save(resource: po)
    ChangeSetPersister.default.query_service.find_by(id: po.id)
  end

  def create_resource_no_lock_token
    allow(ScannedResource).to receive(:optimistic_locking_enabled?).and_return(false)
    preserved_resource = FactoryBot.create_for_repository(:complete_scanned_resource, run_callbacks: true)
    po = Wayfinder.for(preserved_resource).preservation_object
    po.metadata_version = nil
    ChangeSetPersister.default.metadata_adapter.persister.save(resource: po)
    allow(ScannedResource).to receive(:optimistic_locking_enabled?).and_return(true)
    ChangeSetPersister.default.query_service.find_by(id: preserved_resource.id)
  end
end
