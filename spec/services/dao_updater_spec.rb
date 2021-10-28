# frozen_string_literal: true

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
    context "when the resource is private" do
      it "does nothing" do
        resource = FactoryBot.create_for_repository(:complete_private_scanned_resource)
        change_set_persister = instance_double(ChangeSetPersister)

        updater = described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister)

        # We haven't stubbed ASpace, so webmock will error if it tries to do
        # something.
        updater.update!
      end
    end
    context "when no resource is found in aspace" do
      it "throws an error" do
        stub_aspace_login

        stub_aspace(pulfa_id: "MC230_c117")
        stub_find_archival_object_not_found(component_id: "MC230_c117")

        resource = FactoryBot.create_for_repository(:complete_open_scanned_resource, source_metadata_identifier: "MC230_c117")
        change_set_persister = instance_double(ChangeSetPersister)

        updater = described_class.new(change_set: ChangeSet.for(resource), change_set_persister: change_set_persister)

        updater.update!
      end
    end
  end
end
