# frozen_string_literal: true
require "rails_helper"
include ActionDispatch::TestProcess

RSpec.describe Mutations::UpdateEvent do
  describe "schema" do
    subject { described_class }
    it { is_expected.to have_field(:resource) }
    it { is_expected.to have_field(:errors) }
    it {
      is_expected.to accept_arguments(
        messages: "[String!]"
      )
    }
  end
  let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource) }
  let(:preservation_object) { FactoryBot.create_for_repository(:preservation_object, preserved_object_id: scanned_resource.id) }
  let(:resource) { FactoryBot.create_for_repository(:event, modified_resource_ids: preservation_object.id) }

  before do
    resource
  end

  context "when given permission" do
    context "when given good data" do
      it "updates the record" do
        mutation = create_mutation

        output = mutation.resolve(messages: ["New test message"], modified_resource_ids: [preservation_object.id.to_s])
        expect(output[:resource].messages).to eq ["New test message"]
      end
    end
  end

  context "without permission" do
    it "returns an error and nothing in resource" do
      mutation = create_mutation(update_permission: false, read_permission: false)

      output = mutation.resolve(messages: ["New test message"], modified_resource_ids: [preservation_object.id.to_s])
      expect(output[:resource]).to be_nil
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  context "when you have read permission, but no update permission" do
    it "returns an error with the unchanged resource" do
      mutation = create_mutation(update_permission: false, read_permission: true)

      output = mutation.resolve(messages: ["New test message"], modified_resource_ids: [preservation_object.id.to_s])
      expect(output[:resource].messages).to eq ["Test message"]
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
