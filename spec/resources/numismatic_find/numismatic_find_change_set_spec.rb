# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticFindChangeSet do
  subject(:change_set) { described_class.new(find) }
  let(:find) { FactoryBot.build(:numismatic_find) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:date, :place, :feature, :description)
      expect(change_set.primary_terms).not_to include(:find_number)
    end
  end
end
