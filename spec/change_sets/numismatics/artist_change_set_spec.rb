# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ArtistChangeSet do
  subject(:change_set) { described_class.new(artist) }
  let(:artist) { Numismatics::Artist.new }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:person_id, :signature, :role, :side)
    end
  end
end
