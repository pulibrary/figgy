# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindSavedIds do
  it "returns all ids which are persisted" do
    resource1 = FactoryBot.create_for_repository(:scanned_resource)
    resource2 = FactoryBot.create_for_repository(:scanned_resource)
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    expect(query_service.custom_queries.find_saved_ids(ids: [resource1.id, resource2.id, Valkyrie::ID.new("bla")])).to contain_exactly resource1.id, resource2.id
  end
end
