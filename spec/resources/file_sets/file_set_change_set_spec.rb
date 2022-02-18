# frozen_string_literal: true

require "rails_helper"

RSpec.describe FileSetChangeSet do
  subject(:change_set) { described_class.new(file_set) }

  let(:file_set) { FactoryBot.build(:file_set) }

  describe "#primary_terms" do
    it "is the title and service targets" do
      expect(change_set.primary_terms).to eq [:title, :service_targets]
    end
  end
end
