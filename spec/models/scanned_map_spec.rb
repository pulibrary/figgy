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
  describe "#media_resource?" do
    it "is not a media resource" do
      expect(scanned_map).not_to be_a_media_resource
    end
  end
end
