# frozen_string_literal: true
require "rails_helper"

RSpec.describe LetterChangeSet do
  subject(:change_set) { described_class.new(form_resource) }
  let(:resource_klass) { ScannedResource }
  let(:resource) { resource_klass.new(title: "Test", rights_statement: rights_statement, visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE, state: "draft") }
  let(:rights_statement) { RightsStatements.no_known_copyright }
  let(:form_resource) { resource }

  it_behaves_like "a ChangeSet"
  it_behaves_like "an optimistic locking change set"

  describe "#workflow" do
    it "has a workflow" do
      expect(change_set.workflow).to be_a(DraftCompleteWorkflow)
      expect(change_set.workflow.draft?).to be true
    end
  end

  describe "#primary_terms" do
    it "has necessary terms" do
      expect(change_set.primary_terms.keys).to eq(["", "Sender", "Recipient"])
      expect(change_set.primary_terms.values.flatten).to include(
        :title,
        :rights_statement,
        :rights_note,
        :change_set,
        :pdf_type,
        :member_of_collection_ids,
        :sender,
        :recipient
      )
    end
  end

  describe "#prepopulate!" do
    it "builds an empty sender/recipient" do
      change_set.prepopulate!
      expect(change_set.sender.first).to be_a NameWithPlaceChangeSet
      expect(change_set.recipient.first).to be_a NameWithPlaceChangeSet
    end
  end

  describe "#sender" do
    it "can be set with a name and place" do
      change_set.validate(sender: [{ name: "Test", place: "Place" }])
      expect(change_set.sender.first.name).to eq "Test"
      expect(change_set.sender.first.place).to eq "Place"
      # Ensure form builder works.
      change_set.sender = []
      change_set.validate("sender_attributes" => { "0" => { name: "Test2", place: "Place" } })
      expect(change_set.sender.first.name).to eq "Test2"
      # Ensure it doesn't result in an empty object if nothing is set
      change_set.sender = []
      change_set.validate(sender: [{ name: "", place: "" }])
      change_set.sync
      expect(change_set.resource.sender).to be_empty
    end
  end

  describe "#recipient" do
    it "can be set with a name and place" do
      change_set.validate(recipient: [{ name: "Test", place: "Place" }])
      expect(change_set.recipient.first.name).to eq "Test"
      expect(change_set.recipient.first.place).to eq "Place"
      # Ensure form builder works.
      change_set.recipient = []
      change_set.validate("recipient_attributes" => { "0" => { name: "Test2", place: "Place" } })
      expect(change_set.recipient.first.name).to eq "Test2"
      # Ensure it doesn't result in an empty object if nothing is set
      change_set.recipient = []
      change_set.validate(recipient: [{ name: "", place: "" }])
      change_set.sync
      expect(change_set.resource.recipient).to be_empty
    end
  end
end
