# frozen_string_literal: true
require 'rails_helper'

RSpec.describe EphemeraTermChangeSet do
  subject(:change_set) { described_class.new(FactoryGirl.build(:ephemera_term)) }
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
  end

  describe "#primary_terms" do
    it 'includes the label, value, the definition, and the vocabulary' do
      expect(change_set.primary_terms).to include :label
      expect(change_set.primary_terms).to include :uri
      expect(change_set.primary_terms).to include :code
      expect(change_set.primary_terms).to include :tgm_label
      expect(change_set.primary_terms).to include :lcsh_label
      expect(change_set.primary_terms).to include :member_of_vocabulary_id
    end
  end
end
