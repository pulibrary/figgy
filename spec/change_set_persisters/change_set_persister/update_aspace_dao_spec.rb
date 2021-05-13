# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::UpdateAspaceDao do
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  it "updates ASpace with a new DAO when an item is marked complete" do
    stub_aspace_login
    stub_aspace(pulfa_id: "MC001.01_c000001")
    stub_ezid(shoulder: shoulder, blade: blade)
    change_set_persister = ScannedResourcesController.change_set_persister
    resource = FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "MC001.01_c000001")
    change_set = ChangeSet.for(resource)
    change_set.validate(state: "complete")
    expect(change_set).to be_valid

    change_set_persister.save(change_set: change_set)

    # Expect that DAO got created, probably via webmock.
    # NOTES:
    # https://github.com/duke-libraries/archivesspace-duke-scripts/blob/master/python/asUpdateDAOs.py
    # client.get("/repositories/5/find_by_id/archival_objects?ref_id[]=WC064_c1868").parsed
    # => {"archival_objects"=>
    #   [{"ref"=>"/repositories/5/archival_objects/818025"}]}
    # client.get(client.get("/repositories/5/find_by_id/archival_objects?ref_id[]=WC064_c1868").parsed["archival_objects"][0]["ref"]).parsed
    # digital_objects = obj["instances"].select{|x| x["instance_type"] == "digital_object"}
  end
end
