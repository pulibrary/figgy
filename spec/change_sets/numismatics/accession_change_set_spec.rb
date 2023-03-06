# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::AccessionChangeSet do
  subject(:change_set) { described_class.new(accession) }
  let(:accession) { FactoryBot.build(:numismatic_accession) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms.keys).to eq(["", "Citation"])
      expect(change_set.primary_terms[""]).to include(:date, :items_number, :person_id, :firm_id, :type, :cost, :account)
      expect(change_set.primary_terms[""]).not_to include(:accession_number)
    end
  end

  describe "date validation" do
    context "when an invalid date is set" do
      let(:change_set) { described_class.new(accession, date: "Today") }

      it "is invalid" do
        expect(change_set).not_to be_valid
      end
    end

    context "when a valid date is set" do
      valid_date = "2001-01-01"
      let(:change_set) { described_class.new(accession, date: valid_date) }

      it "is valid" do
        expect(change_set).to be_valid
      end
    end
  end
end
