# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::CitationChangeSet do
  subject(:change_set) { described_class.new(numismatic_citation) }
  let(:numismatic_citation) { Numismatics::Citation.new }

  it_behaves_like "an optimistic locking change set"

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:part, :number, :numismatic_reference_id)
    end
  end
end
