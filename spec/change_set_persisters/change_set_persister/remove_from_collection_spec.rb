# frozen_string_literal: true

require "rails_helper"

RSpec.describe ChangeSetPersister::RemoveFromCollection do
  with_queue_adapter :inline
  it "can remove a collection from a resource" do
    collection1 = FactoryBot.create_for_repository(:collection)
    change_set_persister = ChangeSetPersister.default
    resource = FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: [collection1.id])
    change_set = ChangeSet.for(resource)

    change_set.validate(remove_collection_ids: [collection1.id.to_s])
    output = change_set_persister.save(change_set: change_set)

    expect(output.member_of_collection_ids).to be_empty
  end
end
