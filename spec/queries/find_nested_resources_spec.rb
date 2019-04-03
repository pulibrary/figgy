# frozen_string_literal: true
require "rails_helper"

RSpec.describe FindNestedResources do
  subject(:query) { described_class.new(query_service: query_service) }
  let(:citation1) { NumismaticCitation.new(part: "citation part 1", number: "citation number 1") }
  let(:citation2) { NumismaticCitation.new(part: "citation part 2", number: "citation number 2") }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, citation: [citation1, citation2]) }
  let(:query_service) { Valkyrie.config.metadata_adapter.query_service }

  describe "#find_nested_resources" do
    before do
      citation1
      citation2
      issue
    end

    it "can find resources nested in another resource" do
      output = query.find_nested_resources(property: :citation)
      expect(output.length).to eq 2
      output_ids = output.map(&:id)
      expect(output_ids).to include citation1.id
      expect(output_ids).to include citation2.id
    end
  end
end
