# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindNestedReferencesBy do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
  let(:numismatic_citation) { FactoryBot.create_for_repository(:numismatic_citation, numismatic_reference_id: [reference.id]) }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, numismatic_citation: numismatic_citation) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_nested_resources" do
    before do
      reference
      numismatic_citation
      issue
    end

    it "can find resources nested in another resource" do
      output = query.find_nested_references_by(resource: numismatic_citation, nested_property: :numismatic_citation, property: :numismatic_reference_id).first
      expect(output.id).to eq reference.id
    end
  end
end
