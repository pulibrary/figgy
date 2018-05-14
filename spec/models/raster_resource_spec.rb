# frozen_string_literal: true
require "rails_helper"
require "valkyrie/specs/shared_specs"

RSpec.describe RasterResource do
  subject(:raster_resource) { described_class.new(title: "test title") }
  let(:resource_klass) { described_class }
  it_behaves_like "a Valkyrie::Resource"
  it "has a title" do
    expect(raster_resource.title).to include "test title"
  end
  it "does not have manifests" do
    expect(raster_resource.class.can_have_manifests?).to be false
  end
  it "is a geo resource" do
    expect(raster_resource.geo_resource?).to be true
  end
end
