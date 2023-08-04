# frozen_string_literal: true
require "rails_helper"

describe DeletionMarkerService do
  with_queue_adapter :inline

  let(:change_set_persister) { ChangeSetPersister.default }
  let(:query_service) { change_set_persister.query_service }

  before do
    # Make preservation deletes not actually happen to simulate a versioned
    # file store.
    allow(Valkyrie::StorageAdapter.find(:google_cloud_storage)).to receive(:delete)
    # This is a bug - right now all disk:// storage adapter IDs are going to
    # this adapter, no matter what, so the above never gets called.
    allow(Valkyrie::StorageAdapter.find(:disk)).to receive(:delete)
    stub_ezid
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

  context "when restoring an EphemeraProject" do
    it "restores it " do
      project = FactoryBot.create_for_repository(:ephemera_project)
      project = ChangeSetPersister.default.save(change_set: ChangeSet.for(project))
      change_set_persister.delete(change_set: ChangeSet.for(project))
      project_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(project.id)).first

      described_class.restore(project_deletion_marker.id)
      projects = query_service.find_all_of_model(model: EphemeraProject)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(projects.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring an EphemeraBox" do
    it "restores it" do
      resource = FactoryBot.build(:ephemera_box)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: EphemeraBox)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring an EphemeraFolder" do
    it "restores it" do
      resource = FactoryBot.build(:ephemera_folder)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: EphemeraFolder)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring an EphemeraField" do
    it "restores it" do
      resource = FactoryBot.build(:ephemera_field)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: EphemeraField)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring an EphemeraVocabulary" do
    it "restores it" do
      resource = FactoryBot.build(:ephemera_vocabulary)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: EphemeraVocabulary)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring an EphemeraTerm" do
    it "restores it" do
      resource = FactoryBot.build(:ephemera_term)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: EphemeraTerm)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Collection" do
    it "restores it" do
      resource = FactoryBot.build(:collection)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Collection)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a FileSet only" do
    it "restores the FileSet and re-attaches it to its parent" do
      file = fixture_file_upload("files/example.tif", "image/tiff")
      resource = FactoryBot.create_for_repository(:pending_scanned_map, title: "title", files: [file])
      reloaded_resource = query_service.find_by(id: resource.id)
      change_set = ChangeSet.for(reloaded_resource)
      change_set.validate(state: "complete")
      output = change_set_persister.save(change_set: change_set)
      file_set = Wayfinder.for(output).members.first
      change_set = ChangeSet.for(file_set)
      change_set_persister.delete(change_set: change_set)
      file_set_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(file_set.id), model: DeletionMarker).first
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

  context "when restoring a ScannedResource" do
    it "restores it" do
      resource = FactoryBot.build(:complete_scanned_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: ScannedResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a MVW" do
    it "restores it and attached resources" do
      resource = FactoryBot.build(:complete_scanned_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      mvw = FactoryBot.build(:complete_scanned_resource, member_ids: [resource.id])
      mvw = ChangeSetPersister.default.save(change_set: ChangeSet.for(mvw))
      change_set_persister.delete(change_set: ChangeSet.for(mvw))
      mvw_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(mvw.id)).first

      resources = query_service.find_all_of_model(model: ScannedResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      expect(resources.count).to eq 0
      expect(dm.count).to eq 2

      described_class.restore(mvw_deletion_marker.id)
      resources = query_service.find_all_of_model(model: ScannedResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      mvw = query_service.find_by(id: mvw.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(mvw.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a volume in a MVW" do
    it "restores it and reattaches it to the parent resource" do
      resource = FactoryBot.build(:complete_scanned_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      mvw = FactoryBot.build(:complete_scanned_resource, member_ids: [resource.id])
      mvw = ChangeSetPersister.default.save(change_set: ChangeSet.for(mvw))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: ScannedResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      mvw = query_service.find_by(id: mvw.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(mvw.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a MapSet" do
    it "restores it and attached resources" do
      resource = FactoryBot.build(:complete_scanned_map)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      map_set = FactoryBot.build(:complete_scanned_map, member_ids: [resource.id])
      map_set = ChangeSetPersister.default.save(change_set: ChangeSet.for(map_set))
      change_set_persister.delete(change_set: ChangeSet.for(map_set))
      map_set_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(map_set.id)).first

      resources = query_service.find_all_of_model(model: ScannedMap)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      expect(resources.count).to eq 0
      expect(dm.count).to eq 2

      described_class.restore(map_set_deletion_marker.id)
      resources = query_service.find_all_of_model(model: ScannedMap)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      map_set = query_service.find_by(id: map_set.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(map_set.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a map in a MapSet" do
    it "restores it and reattaches it to the parent resource" do
      resource = FactoryBot.build(:complete_scanned_map)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      map_set = FactoryBot.build(:complete_scanned_map, member_ids: [resource.id])
      map_set = ChangeSetPersister.default.save(change_set: ChangeSet.for(map_set))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: ScannedMap)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      map_set = query_service.find_by(id: map_set.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(map_set.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a RasterResource" do
    it "restores it" do
      resource = FactoryBot.build(:complete_raster_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: RasterResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a RasterSet" do
    it "restores it and attached resources" do
      resource = FactoryBot.build(:complete_raster_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      raster_set = FactoryBot.build(:complete_raster_resource, member_ids: [resource.id])
      raster_set = ChangeSetPersister.default.save(change_set: ChangeSet.for(raster_set))
      change_set_persister.delete(change_set: ChangeSet.for(raster_set))
      raster_set_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(raster_set.id)).first

      resources = query_service.find_all_of_model(model: ScannedMap)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      expect(resources.count).to eq 0
      expect(dm.count).to eq 2

      described_class.restore(raster_set_deletion_marker.id)
      resources = query_service.find_all_of_model(model: RasterResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      raster_set = query_service.find_by(id: raster_set.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(raster_set.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a raster resource in a RasterSet" do
    it "restores it and reattaches it to the parent resource" do
      resource = FactoryBot.build(:complete_raster_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      raster_set = FactoryBot.build(:complete_raster_resource, member_ids: [resource.id])
      raster_set = ChangeSetPersister.default.save(change_set: ChangeSet.for(raster_set))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: RasterResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)
      raster_set = query_service.find_by(id: raster_set.id)

      expect(resources.count).to eq 2
      expect(dm.count).to eq 0
      expect(raster_set.member_ids).to eq([resource.id])
    end
  end

  context "when restoring a VectorResource" do
    it "restores it" do
      resource = FactoryBot.build(:complete_vector_resource)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: VectorResource)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Playlist" do
    it "restores it" do
      resource = FactoryBot.build(:complete_playlist)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Playlist)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Issue" do
    it "restores it attached coins" do
      coin = FactoryBot.build(:complete_open_coin)
      coin = ChangeSetPersister.default.save(change_set: ChangeSet.for(coin))
      resource = FactoryBot.build(:complete_open_numismatic_issue, member_ids: [coin.id])
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      resources = query_service.find_all_of_model(model: Numismatics::Issue)
      coins = query_service.find_all_of_model(model: Numismatics::Coin)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 0
      expect(coins.count).to eq 0
      expect(dm.count).to eq 2

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Issue)
      coins = query_service.find_all_of_model(model: Numismatics::Coin)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(coins.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Coin" do
    it "restores it" do
      resource = FactoryBot.build(:complete_open_coin)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Coin)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Reference" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_reference)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Reference)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Monogram" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_monogram)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Monogram)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Accession" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_accession)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Accession)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Firm" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_firm)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Firm)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Person" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_person)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Person)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end

  context "when restoring a Numismatics::Place" do
    it "restores it" do
      resource = FactoryBot.build(:numismatic_place)
      resource = ChangeSetPersister.default.save(change_set: ChangeSet.for(resource))
      change_set_persister.delete(change_set: ChangeSet.for(resource))
      resource_deletion_marker = query_service.custom_queries.find_by_property(property: :resource_id, value: Valkyrie::ID.new(resource.id)).first

      described_class.restore(resource_deletion_marker.id)
      resources = query_service.find_all_of_model(model: Numismatics::Place)
      dm = query_service.find_all_of_model(model: DeletionMarker)

      expect(resources.count).to eq 1
      expect(dm.count).to eq 0
    end
  end
end
