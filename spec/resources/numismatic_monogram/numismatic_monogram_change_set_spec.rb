# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticMonogramChangeSet do
  subject(:change_set) { described_class.new(monogram) }
  let(:monogram) { FactoryBot.build(:numismatic_monogram) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:title)
    end
  end
end
