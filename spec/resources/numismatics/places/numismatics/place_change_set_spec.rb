# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::PlaceChangeSet do
  subject(:change_set) { described_class.new(numismatic_place) }
  let(:numismatic_place) { FactoryBot.build(:numismatic_place) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:city, :geo_state, :region)
    end
  end

  describe "#new_record?" do
    it "returns false for supporting nested form integration" do
      expect(change_set.new_record?).to be false
    end
  end

  describe "#marked_for_destruction?" do
    it "returns false for supporting nested form integration" do
      expect(change_set.marked_for_destruction?).to be false
    end
  end
end
