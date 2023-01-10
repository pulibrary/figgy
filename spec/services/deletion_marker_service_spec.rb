# frozen_string_literal: true
require "rails_helper"

describe DeletionMarkerService do
  with_queue_adapter :inline

  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }

  before do
    # Make preservation deletes not actually happen to simulate a versioned
    # file store.
    allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:delete)
    # This is a bug - right now all disk:// storage adapter IDs are going to
    # this adapter, no matter what, so the above never gets called.
    allow(Valkyrie::StorageAdapter.find(:disk)).to receive(:delete)
    stub_ezid(shoulder: shoulder, blade: blade)
  end

  context "when restoring a deleted resource with children" do
    it "restores the resouce and child resources" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      child_resource = FactoryBot.create_for_repository(:complete_raster_resource)
      resource = FactoryBot.create_for_repository(:pending_scanned_map, title: "title", member_ids: [child_resource.id], files: [file])
      reloaded_resource = query_service.find_by(id: resource.id)
      change_set = ChangeSet.for(reloaded_resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)
      change_set = ChangeSet.for(output)
      change_set_persister.delete(change_set: change_set)

      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)

      sm = query_service.find_all_of_model(model: ScannedMap)
      rr = query_service.find_all_of_model(model: RasterResource)
      fs = query_service.find_all_of_model(model: FileSet)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(sm.count).to eq 1
      expect(rr.count).to eq 1
      expect(fs.count).to eq 1
      expect(dm.count).to eq 0
      expect(fs.first.mime_type).to eq ["image/tiff"]
    end
  end

  context "when restoring a FileSet only" do
    it "restores the FileSet and re-attaches it to it's parent" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:pending_scanned_map, title: "title", files: [file])
      reloaded_resource = query_service.find_by(id: resource.id)
      change_set = ChangeSet.for(reloaded_resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)
      file_set = Wayfinder.for(output).members.first
      change_set = ChangeSet.for(file_set)
      change_set_persister.delete(change_set: change_set)
      file_set_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(file_set.id)).first
      reloaded_resource = query_service.find_by(id: resource.id)

      expect(reloaded_resource.member_ids).to be_empty

      described_class.restore(file_set_deletion_marker.id)

      reloaded_resource = query_service.find_by(id: resource.id)
      fs = query_service.find_all_of_model(model: FileSet)

      expect(reloaded_resource.member_ids).not_to be_empty
      expect(fs.count).to eq 1
      expect(fs.first.mime_type).to eq ["image/tiff"]
    end
  end
end
