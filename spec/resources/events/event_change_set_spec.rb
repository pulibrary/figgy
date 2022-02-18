# frozen_string_literal: true

require "rails_helper"

RSpec.describe EventChangeSet do
  subject(:change_set) { described_class.new(event) }

  let(:type) { "Test type" }
  let(:status) { "Test status" }
  let(:resource_id) { Valkyrie::ID.new("test1") }
  let(:child_property) { "binary_node" }
  let(:child_id) { Valkyrie::ID.new("test2") }
  let(:message) { "Test message" }
  let(:event) do
    FactoryBot.build(:event,
      type: type,
      status: status,
      resource_id: resource_id,
      child_property: child_property,
      child_id: child_id,
      message: message)
  end

  describe "#type" do
    it "access the type property" do
      expect(change_set.type).to eq type
    end
  end

  describe "#status" do
    it "access the status property" do
      expect(change_set.status).to eq status
    end
  end

  describe "#resource_id" do
    it "access the resource_id property" do
      expect(change_set.resource_id).to eq resource_id
    end
  end

  describe "#child_property" do
    it "access the child_property property" do
      expect(change_set.child_property).to eq child_property
    end
  end

  describe "#child_id" do
    it "access the child_id property" do
      expect(change_set.child_id).to eq child_id
    end
  end

  describe "#message" do
    it "access the message property" do
      expect(change_set.message).to eq message
    end
  end

  describe "#preserve?" do
    it "is not preserved" do
      expect(change_set.preserve?).to be false
    end
  end
end
