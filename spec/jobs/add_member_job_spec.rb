# frozen_string_literal: true

require "rails_helper"

describe AddMemberJob do
  let(:resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:parent) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:metadata_adapter) { Valkyrie.config.metadata_adapter }

  describe "#perform" do
    before do
      parent
      resource
    end

    it "adds the resource to the parent" do
      described_class.perform_now(resource_id: resource.id.to_s, parent_id: parent.id.to_s)

      persisted = metadata_adapter.query_service.find_by(id: parent.id)
      expect(persisted.member_ids).to include(resource.id)
    end
  end
end
