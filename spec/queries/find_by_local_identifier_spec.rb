# frozen_string_literal: true

require "rails_helper"

RSpec.describe FindByLocalIdentifier do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:box) { FactoryBot.create_for_repository(:ephemera_box, local_identifier: "a0000") }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_by_local_identifier" do
    it "can find objects by a local identifier string" do
      output = query.find_by_local_identifier(local_identifier: box.local_identifier.first).first
      expect(output.id).to eq box.id
    end
  end
end
