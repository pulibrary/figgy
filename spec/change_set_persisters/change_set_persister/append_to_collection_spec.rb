# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::AppendToCollection do
  with_queue_adapter :inline
  it "can append a collection to the resource" do
    collection1 = FactoryBot.create_for_repository(:collection)
    collection2 = FactoryBot.create_for_repository(:collection)
    change_set_persister = ScannedResourcesController.change_set_persister
    resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])
    change_set = ChangeSet.for(resource)

    change_set.validate(append_collection_ids: [collection2.id.to_s])
    output = change_set_persister.save(change_set: change_set)

    expect(output.member_of_collection_ids).to eq [collection1.id, collection2.id]
  end
end
