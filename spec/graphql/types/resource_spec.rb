# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::Resource do
  describe ".resolve_type" do
    it "returns a ScannedResourceType for a ScannedResource" do
      expect(described_class.resolve_type(ScannedResource.new, {})).to eq Types::ScannedResourceType
    end
  end
end
