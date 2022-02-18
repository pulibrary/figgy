# frozen_string_literal: true

require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe ScannedMap do
  subject(:scanned_map) { described_class.new(title: "test title") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(scanned_map.title).to include "test title"
  end
  it "can have manifests" do
    expect(scanned_map.class.can_have_manifests?).to be true
  end
  describe "#recording?" do
    it "is not a recording" do
      expect(scanned_map).not_to be_a_recording
    end
  end

  describe "#linked_resource" do
    it "builds an object modeling the resource graph generalizing all resources" do
      resource = FactoryBot.create_for_repository(:scanned_map)
      linked_resource = resource.linked_resource

      expect(linked_resource).to be_a LinkedData::LinkedImportedResource
      expect(linked_resource.resource).to eq resource
    end
  end
end
