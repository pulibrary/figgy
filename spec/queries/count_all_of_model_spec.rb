# frozen_string_literal: true

require "rails_helper"

RSpec.describe CountAllOfModel do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#count_all_of_model" do
    it "can give a count of all members" do
      FactoryBot.create_for_repository(:scanned_resource)
      FactoryBot.create_for_repository(:scanned_resource)
      FactoryBot.create_for_repository(:ephemera_folder)
      expect(query.count_all_of_model(model: ScannedResource)).to eq 2
    end
  end
end
