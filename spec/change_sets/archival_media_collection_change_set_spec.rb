# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ArchivalMediaCollectionChangeSet do
  let(:change_set) { described_class.new(collection, bag_path: "") }
  let(:collection) { FactoryBot.build(:archival_media_collection) }
  let(:form_resource) { collection }

  before do
    change_set.prepopulate!
  end

  describe "#source_metadata_identifier" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:source_metadata_identifier)).to eq false
      expect(change_set.required?(:source_metadata_identifier)).to eq true
    end
  end

  describe "#bag_path" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:bag_path)).to eq false
      expect(change_set.required?(:bag_path)).to eq true
    end
  end

  describe "#visibility" do
    it "is single-valued and optional" do
      expect(change_set.multiple?(:visibility)).to eq false
      expect(change_set.required?(:visibility)).to eq false
    end
  end

  describe "validations" do
    context "when metadata identifier is not set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "") }
      before do
        allow_any_instance_of(BagPathValidator).to receive(:validate).and_return(true)
      end
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when source_metadata_identifier is set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "AC044_c0003") }
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), 'r') }
      before do
        allow_any_instance_of(BagPathValidator).to receive(:validate).and_return(true)
      end

      it "is valid" do
        stub_request(:get, "https://findingaids.princeton.edu/collections/AC044/c0003.xml?scope=record")
          .with(headers: { 'Accept' => '*/*', 'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent' => 'Faraday v0.9.2' })
          .to_return(status: 200, body: file, headers: {})
        expect(change_set).to be_valid
      end
    end

    context "when bag path is not set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "Totally an identifier") }
      before do
        allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
      end
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when bag path is not set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "Totally an identifier") }
      let(:change_set) { described_class.new(collection, bag_path: "/totally/a/bag") }
      before do
        allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
      end
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
  end

  describe "#primary_terms" do
    it "returns the primary terms" do
      expect(change_set.primary_terms).to contain_exactly :source_metadata_identifier, :bag_path
    end
  end
end
