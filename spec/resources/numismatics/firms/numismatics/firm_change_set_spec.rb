# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::FirmChangeSet do
  subject(:change_set) { described_class.new(numismatic_firm) }
  let(:numismatic_firm) { FactoryBot.build(:numismatic_firm) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:city, :name)
    end
  end
end
