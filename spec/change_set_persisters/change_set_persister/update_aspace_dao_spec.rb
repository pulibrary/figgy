# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::UpdateAspaceDao do
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  it "updates ASpace with a new DAO when an item is marked complete" do
    stub_aspace_login
    stub_find_archival_object(component_id: "MC001.01_c000001")
    stub_aspace(pulfa_id: "MC001.01_c000001")
    stub_ezid(shoulder: shoulder, blade: blade)
    mocked_digital_object_create = stub_create_digital_object
    mocked_archival_object_update = stub_archival_object_update(archival_object_id: "260330")
    change_set_persister = ScannedResourcesController.change_set_persister
    resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "MC001.01_c000001")
    change_set = ChangeSet.for(resource)
    change_set.validate(state: "complete")
    expect(change_set).to be_valid

    change_set_persister.save(change_set: change_set)

    expect(mocked_digital_object_create).to have_been_made
    expect(mocked_archival_object_update).to have_been_made
  end
end
