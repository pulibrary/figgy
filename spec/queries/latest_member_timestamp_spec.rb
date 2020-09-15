# frozen_string_literal: true
require "rails_helper"

RSpec.describe LatestMemberTimestamp do
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#latest_member_timestamp" do
    it "finds all children through a hierarchy with a given property" do
      child1 = FactoryBot.create_for_repository(:file_set)
      child2 = FactoryBot.create_for_repository(:file_set)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child1.id, child2.id])
      child2 = query_service.find_by(id: child2.id)

      result = query_service.custom_queries.latest_member_timestamp(resource: parent)
      expect(result).to eq child2.updated_at
    end
  end
end
