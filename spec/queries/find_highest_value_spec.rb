# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindHighestValue do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  before do
    FactoryBot.create_for_repository(:coin, coin_number: 1)
    FactoryBot.create_for_repository(:coin, coin_number: 3)
    FactoryBot.create_for_repository(:coin, coin_number: 2)
  end

  describe "#find_highest_value" do
    it "finds the highest coin number" do
      output = query.find_highest_value(property: :coin_number)
      expect(output).to eq(3)
    end
    it "can handle there being string values" do
      FactoryBot.create_for_repository(:coin, coin_number: "11")

      output = query.find_highest_value(property: :coin_number)

      expect(output).to eq(11)
    end
  end
end
