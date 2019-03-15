# frozen_string_literal: true
require "rails_helper"

RSpec.describe MediaResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:rights_statement) { RightsStatements.no_known_copyright.to_s }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:media_resource) { MediaResource.new(title: "Test", rights_statement: rights_statement, visibility: visibility, state: "draft") }
  let(:form_resource) { media_resource }
  describe "#prepopulate!" do
    it "doesn't make it look changed" do
      expect(change_set).not_to be_changed
      change_set.prepopulate!
      expect(change_set).not_to be_changed
    end
  end
  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
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

  describe "#rights_statement" do
    let(:form_resource) { MediaResource.new(rights_statement: RDF::URI(rights_statement)) }
    it "is singular, required, and converts to an RDF::URI" do
      expect(change_set.rights_statement).to eq RDF::URI(rights_statement)
      change_set.validate(rights_statement: "")
      expect(change_set).not_to be_valid
      change_set.validate(rights_statement: rights_statement)
      expect(change_set.rights_statement).to be_instance_of RDF::URI
    end
    context "when given a blank MediaResource" do
      let(:form_resource) { MediaResource.new }
      it "sets a default Rights Statement" do
        expect(change_set.rights_statement).to eq RDF::URI(rights_statement)
      end
    end
  end

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(DraftCompleteWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end

  describe "#primary_terms" do
    it "includes basic metadata" do
      expect(change_set.primary_terms).to include :local_identifier
      expect(change_set.primary_terms).to include :rights_statement
      expect(change_set.primary_terms).to include :title
    end
  end

  context "with imported metadata and without a title" do
    let(:media_resource) do
      MediaResource.new(
        source_metadata_identifier: "C0652_c0377",
        rights_statement: rights_statement,
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
        state: "draft"
      )
    end

    before do
      stub_pulfa(pulfa_id: "C0652_c0377")
    end

    describe "#valid?" do
      it "is a valid change set" do
        expect(change_set).to be_valid
      end
    end
  end
end
