# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Structure do
  let(:node) { described_class.new(nodes: [StructureNode.new]) }
  describe "#as_json" do
    it "does not build updated_at/created_at for structure nodes" do
      expect(node.as_json["nodes"].first).to eq(
        "internal_resource" => "StructureNode"
      )
    end
  end
end
