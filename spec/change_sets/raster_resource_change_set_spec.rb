# frozen_string_literal: true
require "rails_helper"

RSpec.describe RasterResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:rights_statement) { RightsStatements.copyright_not_evaluated.to_s }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:raster_resource) { RasterResource.new(title: "Test", rights_statement: rights_statement, visibility: visibility, state: "pending") }
  let(:resource_klass) { RasterResource }
  let(:form_resource) { raster_resource }

  before do
    stub_catalog(bib_id: "9965924523506421")
  end

  it_behaves_like "a ChangeSet with EmbargoDate"

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(GeoWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end

  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
    context "when neither title or metadata identifier is set" do
      let(:form_resource) { raster_resource.new(title: "", source_metadata_identifier: "") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when title is an empty array" do
      it "is invalid" do
        expect(change_set.validate(title: [""])).to eq false
      end
    end
    context "when only metadata_identifier is set" do
      let(:form_resource) { raster_resource.new(title: "", source_metadata_identifier: "9965924523506421") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when rights_statement isn't set" do
      let(:form_resource) { raster_resource.new(rights_statement: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when visibility isn't set" do
      let(:form_resource) { raster_resource.new(visibility: [""]) }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid state transition" do
      it "is valid" do
        change_set.validate(state: "final_review")
        expect(change_set).to be_valid
      end
    end
    context "when given an invalid state transition" do
      it "is invalid" do
        change_set.validate(state: "takedown")
        expect(change_set).not_to be_valid
      end
    end
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

  describe "#holding_location" do
    it "converts values to RDF::URIs" do
      change_set.validate(holding_location: "http://test.com/")
      expect(change_set.holding_location).to be_instance_of RDF::URI
    end
  end

  describe "#rights_statement" do
    let(:form_resource) { RasterResource.new(rights_statement: RDF::URI(rights_statement)) }
    it "is singular, required, and converts to an RDF::URI" do
      expect(change_set.rights_statement).to eq RDF::URI(rights_statement)
      change_set.validate(rights_statement: "")
      expect(change_set).not_to be_valid
      change_set.validate(rights_statement: rights_statement)
      expect(change_set.rights_statement).to be_instance_of RDF::URI
    end
    context "when given a blank RasterResource" do
      let(:form_resource) { RasterResource.new }
      it "sets a default Rights Statement" do
        expect(change_set.rights_statement).to eq RDF::URI(rights_statement)
      end
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end

  describe "#notice_type" do
    let(:form_resource) { raster_resource.new(notice_type: "harmful_content") }
    it "has a notice_type property" do
      expect(change_set.notice_type).to eq "harmful_content"
    end
  end
end
