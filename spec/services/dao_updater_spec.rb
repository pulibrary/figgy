require "rails_helper"

RSpec.describe DaoUpdater do
  describe "#update!" do
    context "when the resource is not complete" do
      it "does nothing" do
        resource = FactoryBot.create_for_repository(:scanned_resource, state: "pending")
        change_set_persister = instance_double(ChangeSetPersister)

        updater = described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister)

        # We haven't stubbed ASpace, so webmock will error if it tries to do
        # something.
        updater.update!
      end
    end
    context "when no resource is found in ASpace and it's a collection ID" do
      it "doesn't notify honeybadger" do
        stub_aspace_login

        stub_findingaid(pulfa_id: "C0652")
        stub_find_archival_object_not_found(component_id: "C0652")
        allow(Honeybadger).to receive(:notify)

        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "C0652")
        change_set_persister = instance_double(ChangeSetPersister)

        updater = described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister)

        updater.update!
        expect(Honeybadger).not_to have_received(:notify)
      end
    end

    context "when no resource is found in aspace" do
      it "notifies honeybadger" do
        stub_aspace_login

        stub_findingaid(pulfa_id: "MC230_c117")
        stub_find_archival_object_not_found(component_id: "MC230_c117")
        allow(Honeybadger).to receive(:notify)

        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "MC230_c117")
        change_set_persister = instance_double(ChangeSetPersister)

        updater = described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister)

        updater.update!
        expect(Honeybadger).to have_received(:notify)
      end
    end
  end
end
