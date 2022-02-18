# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationDecorator do
  subject(:decorator) { described_class.new(resource) }
  let(:resource) { FactoryBot.build(:scanned_resource) }

  describe "#iiif_manifest_attributes" do
    it "defaults to no attributes for the IIIF Manifest" do
      expect(decorator.iiif_manifest_attributes).to be_empty
    end
  end
end
