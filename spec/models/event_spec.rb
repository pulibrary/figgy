# frozen_string_literal: true
require "rails_helper"

describe Event do
  subject(:event) do
    described_class.new(type: type,
                        status: status,
                        resource_id: resource_id,
                        child_property: child_property,
                        child_id: child_id,
                        message: message,
                        current: current)
  end
  let(:type) { "Test type" }
  let(:status) { "Test status" }
  let(:resource_id) { Valkyrie::ID.new("test1") }
  let(:child_property) { "binary_node" }
  let(:child_id) { Valkyrie::ID.new("test2") }
  let(:message) { "Test message" }
  let(:current) { true }

  describe "#type" do
    it "access the type attribute" do
      expect(event.type).to eq type
    end
  end

  describe "#status" do
    it "access the status attribute" do
      expect(event.status).to eq status
    end
  end

  describe "#resource_id" do
    it "access the resource_id attribute" do
      expect(event.resource_id).to eq resource_id
    end
  end

  describe "#child_property" do
    it "access the child_property attribute" do
      expect(event.child_property).to eq child_property
    end
  end

  describe "#child_id" do
    it "access the child_id attribute" do
      expect(event.child_id).to eq child_id
    end
  end

  describe "#message" do
    it "access the message attribute" do
      expect(event.message).to eq message
    end
  end

  describe "#current" do
    it "access the current boolean" do
      expect(event.current).to eq current
    end
  end

  context "when creating two current events with the same resource_id and child_id" do
    it "raises an error" do
      change_set_persister = ChangeSetPersister.default
      id1 = Valkyrie::ID.new(SecureRandom.uuid)
      id2 = Valkyrie::ID.new(SecureRandom.uuid)
      event = change_set_persister.save(change_set: ChangeSet.for(described_class.new(resource_id: id1, child_id: id2, current: [true])))
      expect do
        change_set_persister.save(change_set: ChangeSet.for(described_class.new(resource_id: event.resource_id, child_id: event.child_id, current: [true])))
      end.to raise_error(Sequel::UniqueConstraintViolation)
    end
  end

  context "when creating two current metadata_node events with the same resource_id" do
    it "raises an error" do
      change_set_persister = ChangeSetPersister.default
      event = change_set_persister.save(
        change_set: ChangeSet.for(described_class.new(
          resource_id: Valkyrie::ID.new(SecureRandom.uuid),
          child_id: Valkyrie::ID.new(SecureRandom.uuid),
          current: [true],
          type: ["metadata_node"]
        ))
      )
      expect do
        change_set_persister.save(
          change_set: ChangeSet.for(described_class.new(
            resource_id: event.resource_id,
            child_id: Valkyrie::ID.new(SecureRandom.uuid),
            current: [true],
            type: ["metadata_node"]
          ))
        )
      end.to raise_error(Sequel::UniqueConstraintViolation)
    end
  end
end
