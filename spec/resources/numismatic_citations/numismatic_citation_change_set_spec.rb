# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticCitationChangeSet do
  subject(:change_set) { described_class.new(numismatic_citation) }
  let(:numismatic_citation) { NumismaticCitation.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:part, :number, :numismatic_reference_id)
    end
  end
end
