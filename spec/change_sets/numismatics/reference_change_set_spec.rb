# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ReferenceChangeSet do
  subject(:change_set) { described_class.new(reference) }
  let(:reference) { FactoryBot.build(:numismatic_reference) }

  describe "#primary_terms" do
    it "includes displayed fields" do
      expect(change_set.primary_terms).to include(:title, :short_title, :author_id, :part_of_parent)
    end
  end
end
