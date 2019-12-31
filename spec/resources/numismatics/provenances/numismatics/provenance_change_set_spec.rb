# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ProvenanceChangeSet do
  subject(:change_set) { described_class.new(provenance) }
  let(:provenance) { Numismatics::Provenance.new }

  it_behaves_like "an optimistic locking change set"

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:date, :note, :person_id, :firm_id)
    end
  end
end
