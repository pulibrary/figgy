# frozen_string_literal: true
require "rails_helper"

describe AddEphemeraToCollection do
  with_queue_adapter :inline
  context "when project has EphemeraBoxes" do
    subject(:service) do
      described_class.new(project_id: project.id,
                          collection_id: collection.id,
                          change_set_persister: change_set_persister,
                          logger: logger)
    end
    let(:project) do
      FactoryBot.create_for_repository(:ephemera_project,
                                       member_ids: box.id)
    end
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:box) do
      FactoryBot.create_for_repository(:ephemera_box,
                                       member_ids: folder.id)
    end
    let(:folder) { FactoryBot.create_for_repository(:complete_ephemera_folder) }

    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
    let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:logger) { Logger.new(nil) }

    it "adds folder to collection" do
      expect(collection.decorate.members.count).to eq(0)
      service.add_ephemera
      expect(collection.decorate.members.count).to eq(1)
      expect(collection.decorate.members.first).to be_a_kind_of(EphemeraFolder)
      expect(collection.decorate.members.first.id).to eq(folder.id)
    end
  end

  context "when project has only EphemeraFolders" do
    subject(:service) do
      described_class.new(project_id: project.id,
                          collection_id: collection.id,
                          change_set_persister: change_set_persister,
                          logger: logger)
    end
    let(:project) do
      FactoryBot.create_for_repository(:ephemera_project,
                                       member_ids: folder.id)
    end
    let(:collection) { FactoryBot.create_for_repository(:collection) }
    let(:folder) { FactoryBot.create_for_repository(:complete_ephemera_folder) }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: db, storage_adapter: files) }
    let(:db) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:files) { Valkyrie::StorageAdapter.find(:disk_via_copy) }
    let(:logger) { Logger.new(nil) }

    it "adds folder to collection" do
      expect(collection.decorate.members.count).to eq(0)
      service.add_ephemera
      expect(collection.decorate.members.count).to eq(1)
      expect(collection.decorate.members.first).to be_a_kind_of(EphemeraFolder)
      expect(collection.decorate.members.first.id).to eq(folder.id)
    end
  end
end
