# frozen_string_literal: true
require "rails_helper"

RSpec.describe UpdateFixityJob do
  describe ".perform" do
    it "updates fixity" do
      file_set = FactoryBot.create_for_repository(:file_set)
      resource = FactoryBot.create_for_repository(:preservation_object, preserved_object_id: file_set.id, metadata_node: FileMetadata.new(id: SecureRandom.uuid))

      described_class.perform_now(status: "SUCCESS", resource_id: resource.id.to_s, child_id: resource.metadata_node.id.to_s, child_property: "metadata_node")

      events = query_service.find_all_of_model(model: Event)
      expect(events.to_a.length).to eq 1
      event = events.first
      expect(event.resource_id).to eq resource.id
      expect(event.child_id).to eq resource.metadata_node.id
      expect(event.child_property).to eq "metadata_node"
    end
  end

  def query_service
    Valkyrie::MetadataAdapter.find(:postgres).query_service
  end
end
