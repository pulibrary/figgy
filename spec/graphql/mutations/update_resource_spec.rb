# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mutations::UpdateResource do
  describe "schema" do
    subject { described_class }
    it { is_expected.to have_field(:resource) }
    it { is_expected.to have_field(:errors) }
    it { is_expected.to accept_arguments(id: "ID!", viewingHint: "String", label: "String") }
  end

  context "when given permission" do
    context "when given an invalid viewing hint" do
      it "returns an error" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, viewing_hint: "bad")
        expect(output[:errors]).to eq ["Viewing hint is not included in the list"]
      end
    end
    context "when given good data" do
      it "updates the record" do
        resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged", title: "label")
        mutation = create_mutation

        output = mutation.resolve(id: resource.id, viewing_hint: "individuals", label: "label2")
        expect(output[:resource].viewing_hint).to eq ["individuals"]
        expect(output[:resource].title).to eq ["label2"]
      end
    end
  end

  context "without permission" do
    it "returns an error and nothing in resource" do
      resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged")
      mutation = create_mutation(update_permission: false, read_permission: false)

      output = mutation.resolve(id: resource.id, viewing_hint: "individuals")
      expect(output[:resource]).to be_nil
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  context "when you have read permission, but no update permission" do
    it "returns an error with the unchanged resource" do
      resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged")
      mutation = create_mutation(update_permission: false, read_permission: true)

      output = mutation.resolve(id: resource.id, viewing_hint: "individuals")
      expect(output[:resource].viewing_hint).to eq ["paged"]
      expect(output[:errors]).to eq ["You do not have permissions on this resource."]
    end
  end

  def create_mutation(update_permission: true, read_permission: true)
    ability = instance_double(Ability)
    allow(ability).to receive(:can?).with(:update, anything).and_return(update_permission)
    allow(ability).to receive(:can?).with(:read, anything).and_return(read_permission)
    described_class.new(object: nil, context: { ability: ability })
  end
end
