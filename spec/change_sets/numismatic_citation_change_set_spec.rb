# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticCitationChangeSet do
  subject(:change_set) { described_class.new(citation) }
  let(:citation) { FactoryBot.build(:numismatic_citation) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:part, :number, :numismatic_reference_id, :append_id)
    end
  end
end
