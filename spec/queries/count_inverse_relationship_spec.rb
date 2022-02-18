# frozen_string_literal: true

require "rails_helper"

RSpec.describe CountInverseRelationship do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:collection) { FactoryBot.create_for_repository(:collection) }
  let(:member) { FactoryBot.create_for_repository(:scanned_resource, member_of_collection_ids: collection.id) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#count_inverse_relationship" do
    it "can give a count of all members" do
      member
      expect(query.count_inverse_relationship(resource: collection, property: :member_of_collection_ids)).to eq 1
    end
  end
end
