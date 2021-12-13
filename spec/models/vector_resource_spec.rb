# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe VectorResource do
  subject(:vector_resource) { described_class.new(title: "test title") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(vector_resource.title).to include "test title"
  end
  it "does not have manifests" do
    expect(vector_resource.class.can_have_manifests?).to be false
  end
  it "is a geo resource" do
    expect(vector_resource.geo_resource?).to be true
  end

  describe "#linked_resource" do
    it "builds an object modeling the resource graph generalizing all resources" do
      resource = FactoryBot.create_for_repository(:vector_resource)
      linked_resource = resource.linked_resource

      expect(linked_resource).to be_a LinkedData::LinkedImportedResource
      expect(linked_resource.resource).to eq resource
    end
  end
end
