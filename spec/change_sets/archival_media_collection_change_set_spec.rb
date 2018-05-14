# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaCollectionChangeSet do
  let(:change_set) { described_class.new(collection, bag_path: "") }
  let(:collection) { FactoryBot.build(:archival_media_collection, state: "draft") }
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
      let(:file) { File.open(Rails.root.join("spec", "fixtures", "some_finding_aid.xml"), "r") }
      before do
        allow_any_instance_of(BagPathValidator).to receive(:validate).and_return(true)
      end

      it "is valid" do
        stub_pulfa(pulfa_id: "AC044/c0003")
        expect(change_set).to be_valid
      end
    end

    context "when an invalid bag path is set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "Totally an identifier") }
      let(:change_set) { described_class.new(collection, bag_path: "/not/a/bag") }

      before do
        allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
        allow(Dir).to receive(:exist?).and_return(false)
      end
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when a valid bag path is set" do
      let(:collection) { FactoryBot.build(:archival_media_collection, source_metadata_identifier: "Totally an identifier") }
      let(:change_set) { described_class.new(collection, bag_path: "/totally/a/bag") }

      before do
        allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
        allow(Dir).to receive(:exist?).and_return(true)
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

  describe "#workflow" do
    it "has a workflow" do
      change_set.prepopulate!
      expect(change_set.workflow).to be_a(DraftPublishWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end
end
