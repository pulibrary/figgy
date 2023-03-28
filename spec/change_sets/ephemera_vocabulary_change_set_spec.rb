# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraVocabularyChangeSet do
  subject(:change_set) { described_class.new(FactoryBot.build(:ephemera_vocabulary)) }
  describe "validations" do
    it "is valid by default" do
      expect(change_set).to be_valid
    end
    context "when given a bad label" do
      it "is invalid" do
        change_set.validate(label: nil)
        expect(change_set).not_to be_valid
      end
    end
    context "when given a non-UUID for a parent vocabulary" do
      it "is not valid" do
        change_set.validate(member_of_vocabulary_id: ["not-valid"])
        expect(change_set).not_to be_valid
      end
    end
    context "when given a valid UUID for a parent resource which does not exist" do
      it "is not valid" do
        change_set.validate(member_of_vocabulary_id: ["b8823acb-d42b-4e62-a5c9-de5f94cbd3f6"])
        expect(change_set).not_to be_valid
      end
    end
  end

  describe "#primary_terms" do
    it "includes the label, URI, the definition, and the vocabulary" do
      expect(change_set.primary_terms).to include :label
      expect(change_set.primary_terms).to include :uri
      expect(change_set.primary_terms).to include :definition
      expect(change_set.primary_terms).to include :member_of_vocabulary_id
    end
  end

  context "when an ephemera vocabulary resource is saved" do
    with_queue_adapter :inline

    it "is preserved" do
      persisted = ChangeSetPersister.default.save(change_set: change_set)
      expect(Wayfinder.for(persisted).preservation_object).not_to be_nil
    end
  end
end
