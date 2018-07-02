# frozen_string_literal: true
require "rails_helper"

RSpec.describe Types::Resource do
  describe "fields" do
    subject { described_class }
    it { is_expected.to have_field(:id).of_type(String) }
    it { is_expected.to have_field(:url).of_type(String) }
    it { is_expected.to have_field(:label).of_type(String) }
    it { is_expected.to have_field(:viewingHint).of_type(String) }
    it { is_expected.to have_field(:members) }
    it { is_expected.to have_field(:sourceMetadataIdentifier) }
  end
  describe ".resolve_type" do
    it "returns a ScannedResourceType for a ScannedResource" do
      expect(described_class.resolve_type(ScannedResource.new, {})).to eq Types::ScannedResourceType
    end
    it "returns a FileSetType for a FileSet" do
      expect(described_class.resolve_type(FileSet.new, {})).to eq Types::FileSetType
    end
  end
end
