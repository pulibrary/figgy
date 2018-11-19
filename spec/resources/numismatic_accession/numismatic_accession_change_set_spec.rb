# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticAccessionChangeSet do
  subject(:change_set) { described_class.new(accession) }
  let(:accession) { FactoryBot.build(:numismatic_accession) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:date, :person, :firm, :type, :cost, :account)
      expect(change_set.primary_terms).not_to include(:accession_number)
    end
  end
end
