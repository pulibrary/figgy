# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::IIIF do
  before do
    class TestResource < Resource
      include Schema::IIIF
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context "with a new Resource Class" do
    let(:resource) { TestResource.new }

    before do
      resource.nav_date = "test date"
      resource.viewing_direction = "test value"
    end

    it "mixes in the module" do
      expect(resource.class.ancestors).to include(described_class)
    end

    it "defines the schema attributes IIIF for a Resource subclass instances" do
      expect(resource.nav_date).to include "test date"
      expect(resource.viewing_direction).to include "test value"
    end
  end
end
