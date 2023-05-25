# frozen_string_literal: true
require "rails_helper"

RSpec.describe RecordingChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:rights_statement) { RightsStatements.no_known_copyright.to_s }
  let(:visibility) { Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
  let(:scanned_resource) { ScannedResource.new(title: "Test", rights_statement: rights_statement, visibility: visibility, state: "draft") }
  let(:resource_klass) { ScannedResource }
  let(:form_resource) { scanned_resource }

  it_behaves_like "a ChangeSet with EmbargoDate"

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
    let(:form_resource) { ScannedResource.new(rights_statement: RDF::URI(rights_statement)) }
    it "is singular, required, and converts to an RDF::URI" do
      expect(change_set.rights_statement).to eq RDF::URI(rights_statement)
      change_set.validate(rights_statement: "")
      expect(change_set).not_to be_valid
      change_set.validate(rights_statement: rights_statement)
      expect(change_set.rights_statement).to be_instance_of RDF::URI
    end
    context "when given a blank ScannedResource" do
      let(:form_resource) { ScannedResource.new }
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

  describe "#change_set" do
    it "sets a recording default" do
      expect(change_set.change_set).to eq "recording"
    end
  end

  describe "#primary_terms" do
    it "includes basic metadata" do
      expect(change_set.primary_terms).to include :local_identifier
      expect(change_set.primary_terms).to include :rights_statement
      expect(change_set.primary_terms).to include :title
      expect(change_set.primary_terms).to include :member_of_collection_ids
      expect(change_set.primary_terms).to include :source_metadata_identifier
      expect(change_set.primary_terms).to include :change_set
    end
  end

  context "with imported metadata and without a title" do
    let(:scanned_resource) do
      ScannedResource.new(
        source_metadata_identifier: "C0652_c0377",
        rights_statement: rights_statement,
        visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
        state: "draft"
      )
    end

    before do
      stub_findingaid(pulfa_id: "C0652_c0377")
    end

    describe "#valid?" do
      it "is a valid change set" do
        expect(change_set).to be_valid
      end
    end
  end
  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "none"
    end
  end

  describe "#preserve?" do
    context "when not persisted" do
      let(:formresource) { FactoryBot.create_for_repository(:recording) }

      it "is not preserved" do
        expect(change_set.preserve?).to be false
      end
    end

    context "when persisted" do
      let(:form_resource) { FactoryBot.create_for_repository(:complete_recording) }

      context "and incomplete" do
        let(:form_resource) { FactoryBot.create_for_repository(:draft_recording) }
        it "is not preserved" do
          expect(change_set.preserve?).to be false
        end
      end
      it "is preserved" do
        expect(change_set.preserve?).to be true
      end
    end
  end

  describe "#logical_structure" do
    let(:form_resource) { FactoryBot.create_for_repository(:complete_recording) }
    it "responds to it" do
      expect(change_set).to respond_to :logical_structure
    end
  end

  describe "#notice_type" do
    let(:form_resource) do
      FactoryBot.create_for_repository(:complete_recording, notice_type: "harmful_content")
    end
    it "has a notice_type property" do
      expect(change_set.notice_type).to eq "harmful_content"
    end
  end
end
