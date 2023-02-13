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

  describe "#primary_terms" do
    it "expects dates to be DateTime objects" do
      accession.date = "Today"
      expect { decorator.formatted_date }.to raise_error
    end
  end
end
