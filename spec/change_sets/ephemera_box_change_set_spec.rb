# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraBoxChangeSet do
  subject(:change_set) { described_class.new(ephemera_box) }
  let(:form_resource) { FactoryBot.build(:ephemera_box) }
  let(:ephemera_box) { form_resource }
  let(:resource_klass) { EphemeraBox }

  it_behaves_like "a ChangeSet with EmbargoDate"

  describe "#visibility" do
    it "exposes the visibility" do
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
    end
    it "can update the visibility" do
      change_set.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      expect(change_set.visibility).to include Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
    end
  end

  describe "drive_barcode" do
    it "is invalid if the drive barcode is invalid" do
      expect(change_set).to be_valid

      change_set.drive_barcode = ["11111111111111"]
      expect(change_set).not_to be_valid
    end

    it "is valid if the drive barcode is valid" do
      expect(change_set).to be_valid
      change_set.drive_barcode = ["11111111111110"]
      expect(change_set).to be_valid
    end
  end

  describe "#state" do
    it "pre-populates" do
      expect(change_set.state).to eq "new"
    end

    context "when an EphemeraBox has EphemeraFolder members" do
      with_queue_adapter :inline
      subject(:change_set) { described_class.new(ephemera_box) }
      let(:ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder) }
      let(:ephemera_box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: [ephemera_folder.id]) }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

      it "propagates the state to member resources and preserves itself; children preserve themselves" do
        change_set.state = "all_in_production"
        persisted = change_set_persister.save(change_set: change_set)
        expect(Wayfinder.for(persisted).preservation_object).not_to be_nil
        folders = persisted.decorate.folders
        expect(folders).not_to be_empty
        expect(folders.first.state).to eq "complete"
        expect(Wayfinder.for(folders.first).preservation_object).not_to be_nil
      end
    end

    context "when adding an EphemeraFolder to a all_in_production state EphemeraBox" do
      with_queue_adapter :inline
      let(:ephemera_folder) { FactoryBot.create_for_repository(:ephemera_folder) }
      let(:ephemera_box) { FactoryBot.create_for_repository(:ephemera_box, state: :all_in_production) }
      let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
      let(:storage_adapter) { Valkyrie.config.storage_adapter }
      let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

      it "preserves the folder" do
        change_set = ChangeSet.for(ephemera_folder)
        change_set.append_id = ephemera_box.id
        persisted = change_set_persister.save(change_set: change_set)
        expect(persisted.state).not_to eq "complete"
        expect(Wayfinder.for(persisted).preservation_object).not_to be_nil
      end
    end
  end

  describe "validations" do
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "#downloads" do
    it "permits public downloads by default" do
      expect(change_set.downloadable).to eq "public"
    end
  end
end
