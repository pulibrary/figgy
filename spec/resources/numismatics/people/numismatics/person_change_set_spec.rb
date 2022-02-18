# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::PersonChangeSet do
  subject(:change_set) { described_class.new(numismatic_person) }
  let(:numismatic_person) { FactoryBot.build(:numismatic_person) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:name1, :name2, :epithet, :family, :born, :died, :class_of, :years_active_start, :years_active_end)
    end
  end
end
