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
    it { is_expected.to have_field(:orangelightId).of_type(String) }
    it { is_expected.to have_field(:sourceMetadataIdentifier) }
    it { is_expected.to have_field(:thumbnail).of_type("Types::Thumbnail") }
  end
  describe ".resolve_type" do
    it "returns a ScannedResourceType for a ScannedResource" do
      expect(described_class.resolve_type(ScannedResource.new, {})).to eq Types::ScannedResourceType
    end
    it "returns a FileSetType for a FileSet" do
      expect(described_class.resolve_type(FileSet.new, {})).to eq Types::FileSetType
    end
  end

  describe ".helper" do
    it "defines an overridden image_path to just return the given parameter back" do
      type = Types::ScannedResourceType.new(ScannedResource.new, {})

      expect(type.helper.image_path("test")).to eq "test"
    end
  end
end
