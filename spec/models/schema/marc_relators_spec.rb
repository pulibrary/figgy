# frozen_string_literal: true

require "rails_helper"

RSpec.describe Schema::MARCRelators do
  before do
    class TestResource < Resource
      include Schema::MARCRelators
    end
  end

  after do
    Object.send(:remove_const, :TestResource)
  end

  context "with a new Resource Class" do
    let(:resource) { TestResource.new }

    before do
      resource.abridger = "test person1"
      resource.actor = "test person2"
    end

    it "mixes in the module" do
      expect(resource.class.ancestors).to include(described_class)
    end

    it "defines the schema attributes MARCRelators for a Resource subclass instances" do
      expect(resource.abridger).to include "test person1"
      expect(resource.actor).to include "test person2"
    end
  end
end
