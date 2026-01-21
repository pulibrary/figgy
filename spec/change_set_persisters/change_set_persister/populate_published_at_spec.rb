require "rails_helper"

RSpec.describe ChangeSetPersister::PopulatePublishedAt do
  subject(:hook) { described_class.new(change_set_persister: change_set_persister, change_set: change_set) }
  let(:change_set_persister) { instance_double(ChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { EphemeraFolderChangeSet.new(ephemera_folder) }
  let(:ephemera_folder) { FactoryBot.create(:ephemera_folder) }
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }

  describe "#run" do
    context "when changing an ephemera folder to a published state" do
      it "puts a timestamp in the published_at field" do
        expect(change_set.model.published_at).to be_nil
        change_set.validate(state: "complete")
        change_set.sync

        expect(hook.run).to be_a ChangeSet

        expect(change_set.model.published_at).to be_a DateTime
      end
    end

    context "when changing a scanned resource to a published state" do
      let(:change_set) do
        ChangeSet.for(FactoryBot.create(:scanned_resource))
      end

      it "puts a timestamp in the published_at field" do
        change_set.validate(state: "complete")
        change_set.sync

        expect(hook.run).to be_a ChangeSet

        expect(change_set.model.published_at).to be_a DateTime
      end
    end

    context "when changing a scanned map to a published state" do
      let(:change_set) do
        ChangeSet.for(FactoryBot.create(:scanned_map))
      end

      it "puts a timestamp in the published_at field" do
        change_set.validate(state: "complete")
        change_set.sync

        expect(hook.run).to be_a ChangeSet

        expect(change_set.model.published_at).to be_a DateTime
      end
    end

    # Add vector? raster? coin? playlist??

    context "when changing a resource that doesn't have a state" do
      let(:change_set) { EphemeraTermChangeSet.new(FactoryBot.create(:ephemera_term)) }
      it "does not run the hook" do
        expect(hook.run).to be nil
      end
    end

    context "when the state hasn't changed" do
      let(:ephemera_folder) { FactoryBot.create(:complete_ephemera_folder) }
      it "does not run the hook" do
        change_set.validate(state: "complete")
        change_set.sync

        expect(hook.run).to be nil
      end
    end

    context "when the state is being changed to another not-published state" do
      let(:change_set) { ChangeSet.for(FactoryBot.create(:scanned_resource)) }
      it "does not run the hook" do
        change_set.validate(state: :metadata_review)
        change_set.sync

        expect(hook.run).to be nil
      end
    end

    context "when the resource has been published before" do
      let(:change_set) do
        EphemeraFolderChangeSet.new(
          FactoryBot.create(
            :complete_ephemera_folder,
            published_at: DateTime.now
          )
        )
      end
      it "does not run the hook and keeps the original published_at date" do
        expect(hook.run).to be nil
      end
    end
  end
end
