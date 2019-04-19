# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Mutations::ReportCloudFixity do
  with_queue_adapter :inline
  describe "schema" do
    subject { described_class }
    it { is_expected.to have_field(:resource) }
    it { is_expected.to have_field(:errors) }
    it do
      is_expected.to accept_arguments(
        preservationObjectId: "ID!",
        fileMetadataNodeId: "ID!",
        status: "String!"
      )
    end
  end
  let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
  let(:query_service) { adapter.query_service }
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  let(:file) { fixture_file_upload("files/abstract.tiff", "image/tiff") }
  let(:scanned_resource) { FactoryBot.create_for_repository(:complete_scanned_resource, preservation_policy: "cloud", files: [file]) }
  let(:file_set) { scanned_resource.decorate.members.first }
  let(:preservation_object) { Wayfinder.for(file_set).preservation_object }
  let(:metadata_node) { preservation_object.metadata_node }
  let(:binary_nodes) { preservation_object.binary_nodes }
  let(:status) { "success" }

  before do
    stub_ezid(shoulder: shoulder, blade: blade)
    file_set
  end

  context "when given permission" do
    context "when given the ID to the preservation object ID and a file metadata node ID" do
      it "creates the event" do
        mutation = create_mutation

        output = mutation.resolve(preservation_object.id, metadata_node.id, status)
        persisted = output[:resource]
        expect(persisted).to be_a PreservationObject
        event = query_service.find_inverse_references_by(property: :resource_id, id: persisted.id).first
        expect(event).to be_an Event
        expect(event.child_property).to eq ["metadata_node"]
        expect(event.child_id).to eq [metadata_node.id]
        expect(event.status).to eq [status]
      end
    end
    context "when given the ID to the preservation object ID and a binary node ID" do
      it "creates the event" do
        mutation = create_mutation

        output = mutation.resolve(preservation_object.id, binary_nodes.first.id, status)
        persisted = output[:resource]
        expect(persisted).to be_a PreservationObject
        event = query_service.find_inverse_references_by(property: :resource_id, id: persisted.id).first
        expect(event).to be_an Event
        expect(event.child_property).to eq ["binary_nodes"]
        expect(event.child_id).to eq [binary_nodes.first.id]
        expect(event.status).to eq [status]
      end
    end
  end

  context "without permission" do
    it "returns an error and nothing in resource" do
      mutation = create_mutation(update_permission: false, read_permission: false)

      output = mutation.resolve(preservation_object.id, metadata_node.id, status)
      expect(output[:resource]).to be_nil
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  context "when you have read permission, but no update permission" do
    it "returns an error with the unchanged resource" do
      mutation = create_mutation(update_permission: false, read_permission: true)

      output = mutation.resolve(preservation_object.id, metadata_node.id, status)
      persisted = output[:resource]
      expect(persisted).to be_a PreservationObject
      events = query_service.find_inverse_references_by(property: :resource_id, id: persisted.id).first
      expect(events).to be nil
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  def create_mutation(update_permission: true, read_permission: true)
    ability = instance_double(Ability)
    allow(ability).to receive(:can?).with(:update, anything).and_return(update_permission)
    allow(ability).to receive(:can?).with(:read, anything).and_return(read_permission)
    described_class.new(object: nil, context: { ability: ability, change_set_persister: GraphqlController.change_set_persister })
  end
end
