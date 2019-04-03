# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindNestedReferencesBy do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
  let(:citation) { FactoryBot.create_for_repository(:numismatic_citation, part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, citation: citation) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_nested_resources" do
    before do
      reference
      citation
      issue
    end

    it "can find resources nested in another resource" do
      output = query.find_nested_references_by(resource: citation, nested_property: :citation, property: :numismatic_reference_id).first
      expect(output.id).to eq reference.id
    end
  end
end
