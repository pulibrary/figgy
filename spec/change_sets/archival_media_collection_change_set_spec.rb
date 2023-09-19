# frozen_string_literal: true
require "rails_helper"

RSpec.describe ArchivalMediaCollectionChangeSet do
  let(:change_set) { described_class.new(collection, bag_path: "") }
  let(:resource_klass) { ScannedResource }
  let(:collection) { FactoryBot.build(:collection, state: "draft") }
  let(:form_resource) { collection }

  describe "#source_metadata_identifier" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:source_metadata_identifier)).to eq false
      expect(change_set.required?(:source_metadata_identifier)).to eq true
    end
  end

  describe "#bag_path" do
    it "is single-valued and not required" do
      expect(change_set.multiple?(:bag_path)).to eq false
      expect(change_set.required?(:bag_path)).to eq false
    end
  end

  describe "#visibility" do
    it "is single-valued and required" do
      expect(change_set.multiple?(:visibility)).to eq false
      expect(change_set.required?(:visibility)).to eq true
    end
  end

  describe "source metadata identifier validation" do
    before do
      allow_any_instance_of(BagPathValidator).to receive(:validate).and_return(true)
      allow_any_instance_of(UniqueArchivalMediaBarcodeValidator).to receive(:validate).and_return(true)
    end

    context "when metadata identifier is not set" do
      let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when metadata identifier is set to a string that's not an id" do
      let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "not an id") }
      it "is invalid" do
        expect { change_set.valid? }.to raise_error(SourceMetadataIdentifierValidator::InvalidMetadataIdentifierError, "Invalid source metadata ID: not an id")
      end
    end

    context "when source_metadata_identifier is already in use on another amc" do
      let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "AC044_c0003") }

      it "is invalid" do
        FactoryBot.create_for_repository(:collection, source_metadata_identifier: "AC044_c0003")
        stub_findingaid(pulfa_id: "AC044_c0003")

        expect(change_set).not_to be_valid
      end
    end

    context "when source_metadata_identifier is already in use on a scanned resource" do
      let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "AC044_c0003") }

      it "is invalid" do
        stub_findingaid(pulfa_id: "AC044_c0003")
        FactoryBot.create_for_repository(:scanned_resource, source_metadata_identifier: "AC044_c0003")

        expect(change_set).to be_valid
      end
    end

    context "when source_metadata_identifier is set" do
      let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "AC044_c0003") }
      it "is valid" do
        stub_findingaid(pulfa_id: "AC044_c0003")
        expect(change_set).to be_valid
      end
    end
  end

  describe "bag path validation" do
    let(:collection) { FactoryBot.build(:collection, source_metadata_identifier: "totally_an_identifier") }
    before do
      allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
      allow_any_instance_of(UniqueArchivalMediaBarcodeValidator).to receive(:validate).and_return(true)
    end

    context "when an invalid bag path is set" do
      let(:change_set) { described_class.new(collection, bag_path: "/not/a/bag") }
      before do
        allow(Dir).to receive(:exist?).and_return(false)
      end

      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when a valid bag path is set" do
      let(:change_set) { described_class.new(collection, bag_path: "/totally/a/bag") }
      before do
        allow(Dir).to receive(:exist?).and_return(true)
      end

      it "is valid" do
        expect(change_set).to be_valid
      end
    end

    context "when no bag path is set" do
      let(:change_set) { described_class.new(collection) }

      it "is valid" do
        expect(change_set).to be_valid
      end
    end
  end

  describe "UniqueArchivalMediaBarcodeValidator" do
    context "when the collection already has files with that barcode" do
      let(:av_fixture_bag) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag") }
      let(:collection_cid) { "C0652" }
      let(:query_service) { Valkyrie::MetadataAdapter.find(:indexing_persister).query_service }
      with_queue_adapter :inline
      before do
        stub_findingaid(pulfa_id: "C0652")
        stub_findingaid(pulfa_id: "C0652_c0377")
      end

      it "is invalid" do
        # create the collection so we know its id
        collection = FactoryBot.create_for_repository(:collection, source_metadata_identifier: collection_cid)
        # ingest the bag so it has the barcodes
        IngestArchivalMediaBagJob.perform_now(collection_component: collection_cid, bag_path: av_fixture_bag, user: nil, member_of_collection_ids: [collection.id])
        # retrieve the collection via the query service and put it in a change set with the bag
        collection = query_service.find_by(id: collection.id)
        change_set = described_class.new(collection, bag_path: av_fixture_bag)
        expect(change_set).not_to be_valid
      end
    end

    context "when bag_path is empty" do
      let(:collection_cid) { "C0652" }
      before do
        allow_any_instance_of(SourceMetadataIdentifierValidator).to receive(:validate).and_return(true)
      end

      it "is valid" do
        collection = FactoryBot.create_for_repository(:collection)
        change_set = described_class.new(collection, source_metadata_identifier: collection_cid, bag_path: "")
        expect(change_set).to be_valid
      end
    end
  end

  describe "#primary_terms" do
    it "returns the primary terms" do
      expect(change_set.primary_terms).to contain_exactly(
        :source_metadata_identifier,
        :bag_path,
        :slug,
        :change_set,
        :reorganize
      )
    end
  end

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(DraftCompleteWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end
end
