# frozen_string_literal: true
require "rails_helper"

describe UpdateCompletedEphemeraFolders do
  subject(:migration) { described_class.new }
  let(:adapter) { Valkyrie.config.metadata_adapter }
  let(:storage_adapter) { Valkyrie.config.storage_adapter }
  let(:persister) { adapter.persister }
  let(:query_service) { adapter.query_service }
  let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }
  let(:resource_factory) { adapter.metadata_adapter.resource_factory }
  let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:orm_folder) { resource_factory.from_resource(resource: folder) }

  describe "#change" do
    before do
      FactoryBot.create_for_repository(:ephemera_box, state: ["all_in_production"], member_ids: [folder.id])
      orm_folder.metadata[:state] = ["needs_qa"]
      orm_folder.save!
    end

    it "ensures that Ephemera Folders in completed Boxes are marked as complete" do
      migration.change

      expect(orm_folder.reload.metadata["state"]).to eq ["complete"]
    end
  end
end
