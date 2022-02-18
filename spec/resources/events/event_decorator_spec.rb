# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventDecorator do
  subject(:decorated) { described_class.new(resource) }

  let(:file_metadata) { FileMetadata.new(id: SecureRandom.uuid) }
  let(:preservation_object) { FactoryBot.create_for_repository(:preservation_object, metadata_node: file_metadata) }
  let(:resource) { FactoryBot.create_for_repository(:event, resource_id: preservation_object.id, child_id: file_metadata.id, child_property: :metadata_node) }
  let(:resource_klass) { Event }

  describe "#affected_resource" do
    it "retrieves the resource affected by the event" do
      expect(decorated.affected_resource).to be_a PreservationObject
      expect(decorated.affected_resource.id).to eq preservation_object.id
    end
  end

  describe "#affected_child" do
    it "retrieves the resource affected by the event" do
      expect(decorated.affected_child).to be_a FileMetadata
      expect(decorated.affected_child.id).to eq file_metadata.id
    end
  end
end
