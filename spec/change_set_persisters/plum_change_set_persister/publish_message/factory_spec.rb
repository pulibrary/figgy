# frozen_string_literal: true
require "rails_helper"

RSpec.describe PlumChangeSetPersister::PublishMessage::Factory do
  let(:query_service) { instance_double(Valkyrie::Persistence::Memory::QueryService) }
  let(:change_set_persister) { instance_double(PlumChangeSetPersister::Basic, query_service: query_service) }
  let(:change_set) { ScannedResourceChangeSet.new(scanned_resource) }
  let(:scanned_resource) { ScannedResource.new }

  describe ".new" do
    it "initializes a new PublishMessage Object" do
      expect(described_class.new(operation: :create)
              .new(change_set_persister: change_set_persister, change_set: change_set))
        .to be_a PlumChangeSetPersister::PublishCreatedMessage
      expect(described_class.new(operation: :update)
              .new(change_set_persister: change_set_persister, change_set: change_set, post_save_resource: scanned_resource))
        .to be_a PlumChangeSetPersister::PublishUpdatedMessage
      expect(described_class.new(operation: :delete)
              .new(change_set_persister: change_set_persister, change_set: change_set))
        .to be_a PlumChangeSetPersister::PublishDeletedMessage
    end

    it "raises an issue when attempting to initialize a publisher object for unsupported operations" do
      expect do
        described_class.new(operation: :unsupport)
                       .new(change_set_persister: change_set_persister, change_set: change_set)
      end.to raise_error(NotImplementedError, "PlumChangeSetPersister::PublishUnsupportedMessage not supported as a change set persistence handler")
    end
  end
end
