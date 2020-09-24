# frozen_string_literal: true

require "rails_helper"

RSpec.describe ManifestKey do
  context "when given a scanned resource with children" do
    it "combines the parent model, child updated_at, and parent updated_at" do
      child1 = FactoryBot.create_for_repository(:file_set)
      child2 = FactoryBot.create_for_repository(:file_set)
      parent = FactoryBot.create_for_repository(:scanned_resource, member_ids: [child1.id, child2.id])
      parent = Valkyrie.config.metadata_adapter.query_service.find_by(id: parent.id)

      key = described_class.for(parent).to_s

      expect(key).to eq "ScannedResource/#{parent.updated_at.to_f}/#{child2.updated_at.to_f}"
    end
  end
end
