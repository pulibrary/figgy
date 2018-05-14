# frozen_string_literal: true
require "rails_helper"

RSpec.describe EphemeraTermChangeSet do
  subject(:change_set) { described_class.new(ephemera_term) }
  let(:ephemera_vocabulary) { FactoryBot.create_for_repository(:ephemera_vocabulary) }
  let(:ephemera_term) { FactoryBot.create_for_repository(:ephemera_term, member_of_vocabulary_id: ephemera_vocabulary.id) }
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
    it "includes the label, value, the definition, and the vocabulary" do
      expect(change_set.primary_terms).to include :label
      expect(change_set.primary_terms).to include :uri
      expect(change_set.primary_terms).to include :code
      expect(change_set.primary_terms).to include :tgm_label
      expect(change_set.primary_terms).to include :lcsh_label
      expect(change_set.primary_terms).to include :member_of_vocabulary_id
    end
  end
end
