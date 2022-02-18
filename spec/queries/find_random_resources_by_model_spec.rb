# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindRandomResourcesByModel do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_random_resources_by_model" do
    it "finds a random subset of resources" do
      3.times do
        FactoryBot.create_for_repository(:preservation_object)
      end
      FactoryBot.create_for_repository(:scanned_resource)

      result = query.find_random_resources_by_model(limit: 2, model: PreservationObject)

      expect(result.to_a.length).to eq 2
      expect(result.map(&:class).uniq.to_a).to eq [PreservationObject]
    end

    context "when limit is 0" do
      it "returns an empty array" do
        result = query.find_random_resources_by_model(limit: 0, model: PreservationObject)

        expect(result.to_a.length).to eq 0
      end
    end
  end
end
