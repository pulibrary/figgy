# frozen_string_literal: true
require "rails_helper"

RSpec.describe ScannedResourceChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { ScannedResource }
  let(:scanned_resource) { resource_klass.new(title: "Test", rights_statement: rights_statement, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: "pending") }
  let(:rights_statement) { RightsStatements.no_known_copyright }
  let(:form_resource) { scanned_resource }

  before do
    stub_bibdata(bib_id: "123456")
  end

  it_behaves_like "a ChangeSet"

  describe "validations" do
    context "when neither title or metadata identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "") }
      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end
    context "when only metadata_identifier is set" do
      let(:form_resource) { scanned_resource.new(title: "", source_metadata_identifier: "123456") }
      it "is valid" do
        expect(change_set).to be_valid
      end
    end
    context "when given a valid state transition" do
      it "is valid" do
        change_set.validate(state: "metadata_review")
        expect(change_set).to be_valid
      end
    end
    context "when given an invalid state transition" do
      it "is invalid" do
        change_set.validate(state: "takedown")
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

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(BookWorkflow)
      expect(change_set.workflow.pending?).to be true
    end
  end

  describe "#logical_structure" do
    let(:structure) do
      {
        "label": "Top!",
        "nodes": [
          {
            "label": "Chapter 1",
            "nodes": [
              {
                "proxy": resource1.id
              }
            ]
          },
          {
            "label": "Chapter 2",
            "nodes": [
              {
                "proxy": resource2.id
              }
            ]
          }
        ]
      }
    end
    let(:resource1) { FactoryBot.create_for_repository(:file_set) }
    let(:resource2) { FactoryBot.create_for_repository(:file_set) }
    it "can set a whole structure all at once" do
      expect(change_set.validate(logical_structure: [structure])).to eq true

      expect(change_set.logical_structure[0].label).to eq ["Top!"]
      expect(change_set.logical_structure[0].nodes[0].label).to eq ["Chapter 1"]
      expect(change_set.logical_structure[0].nodes[0].nodes[0].proxy).to eq [resource1.id]
      expect(change_set.logical_structure[0].nodes[1].label).to eq ["Chapter 2"]
      expect(change_set.logical_structure[0].nodes[1].nodes[0].proxy).to eq [resource2.id]
    end
    it "has a default label" do
      expect(change_set.logical_structure[0].label).to eq ["Logical"]
    end
  end
  context "when a ScannedResource has ScannedResource members" do
    subject(:change_set) { described_class.new(scanned_resource) }
    let(:scanned_resource_member) { FactoryBot.create_for_repository(:scanned_resource) }
    let(:scanned_resource) { FactoryBot.create_for_repository(:scanned_resource, member_ids: [scanned_resource_member.id]) }
    let(:adapter) { Valkyrie::MetadataAdapter.find(:indexing_persister) }
    let(:storage_adapter) { Valkyrie.config.storage_adapter }
    let(:change_set_persister) { ChangeSetPersister.new(metadata_adapter: adapter, storage_adapter: storage_adapter) }

    it "propagates the state to member resources" do
      change_set.state = "metadata_review"
      persisted = change_set_persister.save(change_set: change_set)
      members = persisted.decorate.members
      expect(members).not_to be_empty
      expect(members.first.state).to include "metadata_review"
    end
  end

  describe "#pdf_type" do
    it "defaults to color" do
      expect(change_set.pdf_type).to eq "color"
    end
  end

  describe "#downloadable" do
    it "has a downloadable property" do
      expect(change_set.downloadable).to eq "public"
    end
  end
end
