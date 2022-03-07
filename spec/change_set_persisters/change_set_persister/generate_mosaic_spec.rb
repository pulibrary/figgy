# frozen_string_literal: true
require "rails_helper"

RSpec.describe ChangeSetPersister::GenerateMosaic do
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:storage_adapter) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    allow(MosaicJob).to receive(:perform_later)
  end

  describe "#run" do
    context "with a MapSet that has child ScannedMaps and Raster grandchildren" do
      it "runs a MosaicJob" do
        scanned_map1 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
        scanned_map2 = FactoryBot.create_for_repository(:scanned_map_with_raster_children)
        map_set = FactoryBot.create_for_repository(:scanned_map, member_ids: [scanned_map1.id, scanned_map2.id])
        change_set = ChangeSet.for(map_set)
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)

        expect(MosaicJob).to have_received(:perform_later)
      end
    end

    context "with a ScannedMap that has a child RasterResource" do
      it "does not run a MosaicJob" do
        scanned_map = FactoryBot.create_for_repository(:scanned_map_with_raster_children, state: "pending")
        change_set = ChangeSet.for(scanned_map)
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)

        expect(MosaicJob).not_to have_received(:perform_later)
      end
    end

    context "with a RasterSet with raster files" do
      it "runs a MosaicJob" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, state: "pending")
        change_set = ChangeSet.for(raster_set)
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)

        expect(MosaicJob).to have_received(:perform_later).with(raster_set.id.to_s)
      end
    end

    context "with a completed RasterSet with raster files" do
      it "does not run a MosaicJob" do
        raster_set = FactoryBot.create_for_repository(:raster_set_with_files, state: "complete")
        change_set = ChangeSet.for(raster_set)
        change_set.validate(title: "new title")
        change_set_persister.save(change_set: change_set)

        expect(MosaicJob).not_to have_received(:perform_later)
      end
    end

    context "with a RasterSet with RasterResource members with no files" do
      it "does not run a MosaicJob" do
        raster1 = FactoryBot.create_for_repository(:raster_resource, state: "pending")
        raster2 = FactoryBot.create_for_repository(:raster_resource, state: "pending")
        raster_set = FactoryBot.create_for_repository(:raster_resource, member_ids: [raster1.id, raster2.id], state: "pending")
        change_set = ChangeSet.for(raster_set)
        change_set.validate(state: "complete")
        change_set_persister.save(change_set: change_set)

        expect(MosaicJob).not_to have_received(:perform_later)
      end
    end
  end
end
