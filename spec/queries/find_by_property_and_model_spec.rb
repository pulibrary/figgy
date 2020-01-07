# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindByPropertyAndModel do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:coin1) { FactoryBot.create_for_repository(:coin) }
  let(:file) { fixture_file_upload('numismatics/coin-images/1O.tif') }
  let(:coin2) { FactoryBot.create_for_repository(:coin, files: [file]) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_property_and_model" do
    context "when no objects have the string in that property" do
      it "returns no results" do
        coin1
        coin2
        output = query.find_by_property_and_model(property: :member_ids, value: [], model: Numismatics::Coin)
        expect(output.to_a.map(&:ids)).to include(coin2.id)
        expect(output.to_a.map(&:ids)).not_to include(coin2.id)
      end
    end
  end
end
