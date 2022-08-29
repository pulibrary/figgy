# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindResourcesWithoutMembers do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:coin1) { FactoryBot.create_for_repository(:coin) }
  let(:coin2) { FactoryBot.create_for_repository(:coin, member_ids: [Valkyrie::ID.new("foo")]) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_resources_without_members" do
    context "when no objects have the string in that property" do
      it "returns no results" do
        coin1
        coin2
        output = query.find_resources_without_members(model: Numismatics::Coin)
        expect(output.to_a.map(&:id)).to include(coin1.id)
        expect(output.to_a.map(&:id)).not_to include(coin2.id)
      end
    end
  end
end
