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

    # Ensure the digital object was made.
    expect(mocked_digital_object_create).to have_been_made
    expect(mocked_digital_object_create.with { |req| req.body.include?("http://www.example.com/concern/scanned_resources/#{change_set.id}/manifest") }).to have_been_made
    # Ensure the archival object was linked to the digital object.
    expect(mocked_archival_object_update).to have_been_made
  end
  it "doesn't update ASpace if there's already a digital object" do
    stub_aspace_login
    stub_find_archival_object(component_id: "MC230_c117")
    stub_find_digital_object(ref: "/repositories/3/digital_objects/12331")
    stub_aspace(pulfa_id: "MC230_c117")
    stub_ezid(shoulder: shoulder, blade: blade)
    mocked_digital_object_create = stub_create_digital_object
    change_set_persister = ScannedResourcesController.change_set_persister
    resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "MC230_c117")
    change_set = ChangeSet.for(resource)
    change_set.validate(state: "complete")
    expect(change_set).to be_valid

    change_set_persister.save(change_set: change_set)

    # Ensure the digital object was made.
    expect(mocked_digital_object_create).not_to have_been_made
  end
end
