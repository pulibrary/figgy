# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetChangeSet do
  subject(:change_set) { described_class.new(FactoryBot.build(:file_set)) }
  describe "#primary_terms" do
    it "is just the title" do
      expect(change_set.primary_terms).to eq [:title]
    end
  end
end
