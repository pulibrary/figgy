# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedMapChangeSet do
  let(:resource_klass) { ScannedMap }
  subject(:change_set) { described_class.new(form_resource) }
  let(:scanned_map) { ScannedMap.new(title: "Test", rights_statement: "Stuff", visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: "pending") }
  let(:form_resource) { scanned_map }
  before do
    stub_bibdata(bib_id: "123456")
  end

  # it_behaves_like "a ChangeSet with EmbargoDate"

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(GeoWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end

  describe "validations" do
    context "when given a non-UUID for a collection" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a collection which does not exist" do
      it "is not valid" do
        change_set.validate(member_of_collection_ids: ["b8823acb-d42b-4e62-a5c9-de5f94cbd3f6"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a non-UUID for a member resource" do
      it "is not valid" do
        change_set.validate(member_ids: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a member resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_ids: ["55a14e79-710d-42c1-86aa-3d8cdaa62930"])
        expect(change_set).not_to be_valid
      end
    end
  end
  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end
end
