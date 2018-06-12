# frozen_string_literal: true
require "rails_helper"

RSpec.describe Mutations::UpdateResource do
  describe "schema" do
    subject { described_class }
    it { is_expected.to have_field(:resource) }
    it { is_expected.to have_field(:errors) }
    it { is_expected.to accept_arguments(id: "ID!", viewingHint: "String") }
  end

  describe "behavior" do
    context "when given an invalid viewing hint" do
      it "returns an error" do
        resource = FactoryBot.create_for_repository(:scanned_resource)
        mutation = described_class.new(object: nil, context: {})

        output = mutation.resolve(id: resource.id, viewing_hint: "bad")
        expect(output[:errors]).to eq ["Viewing hint is not included in the list"]
      end
    end
    context "when given good data" do
      it "updates the record" do
        resource = FactoryBot.create_for_repository(:scanned_resource, viewing_hint: "paged")
        mutation = described_class.new(object: nil, context: {})

        output = mutation.resolve(id: resource.id, viewing_hint: "individuals")
        expect(output[:resource].viewing_hint).to eq ["individuals"]
      end
    end
  end
end
