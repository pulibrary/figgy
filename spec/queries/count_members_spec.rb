# frozen_string_literal: true

require "rails_helper"

RSpec.describe CountMembers do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:box) { FactoryBot.create_for_repository(:ephemera_box, member_ids: folder.id) }
  let(:folder) { FactoryBot.create_for_repository(:ephemera_folder) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#count_members" do
    it "can give a count of all members" do
      expect(query.count_members(resource: box)).to eq 1
    end
    it "can give a count of all members of a specific type" do
      expect(query.count_members(resource: box, model: EphemeraFolder)).to eq 1
      expect(query.count_members(resource: box, model: ScannedResource)).to eq 0
    end
  end
end
