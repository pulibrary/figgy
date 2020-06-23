# frozen_string_literal: true
require "rails_helper"

RSpec.describe PluckEarliestUpdatedAt do
  it "returns all ids which are persisted" do
    resource1 = nil
    Timecop.freeze(Time.now.utc - 10.minutes) do
      resource1 = FactoryBot.create_for_repository(:scanned_resource)
    end
    Timecop.freeze(Time.now.utc - 5.minutes) do
      FactoryBot.create_for_repository(:scanned_resource)
    end
    query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
    expect(query_service.custom_queries.pluck_earliest_updated_at).to eq resource1.updated_at
  end
  context "when there are no resources" do
    it "returns nil" do
      query_service = Valkyrie::MetadataAdapter.find(:indexing_persister).query_service
      expect(query_service.custom_queries.pluck_earliest_updated_at).to eq nil
    end
  end
end
