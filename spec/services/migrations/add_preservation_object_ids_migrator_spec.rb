# frozen_string_literal: true
require "rails_helper"

RSpec.describe Migrations::AddPreservationObjectIdsMigrator do
  describe ".call" do
    let(:query_service) { ChangeSetPersister.default.query_service }
    it "adds IDs to the MetadataNodes of all PreservationObjects" do
      preservation_object1 = create_preservation_object(metadata_id: SecureRandom.uuid)
      create_preservation_object

      before_count = query_service.custom_queries.find_by_property(property: :metadata_node, value: { id: {} }).size
      expect(before_count).to eq 1

      described_class.call

      after_result = query_service.custom_queries.find_by_property(property: :metadata_node, value: { id: {} })
      expect(after_result.size).to eq 2
      expect(after_result.map(&:metadata_node).map(&:id)).to include preservation_object1.metadata_node.id
      expect(after_result.flat_map(&:binary_nodes).map(&:id).compact.length).to eq 2
    end

    it "deletes all events that don't have a child ID" do
      FactoryBot.create_for_repository(
        :event,
        child_id: Valkyrie::ID.new("")
      )
      FactoryBot.create_for_repository(
        :event,
        child_id: Valkyrie::ID.new(SecureRandom.uuid)
      )

      expect(query_service.custom_queries.count_all_of_model(model: Event)).to eq 2

      described_class.call

      expect(query_service.custom_queries.count_all_of_model(model: Event)).to eq 1
    end

    def create_preservation_object(metadata_id: nil)
      FactoryBot.create_for_repository(
        :preservation_object,
        metadata_node: FileMetadata.new(
          id: metadata_id
        ),
        binary_nodes: [
          FileMetadata.new(
            id: metadata_id
          )
        ]
      )
    end
  end
end
