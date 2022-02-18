# frozen_string_literal: true

require "rails_helper"

RSpec.describe TombstoneChangeSet do
  subject(:change_set) { described_class.new(resource) }

  let(:resource) { FactoryBot.create_for_repository(:tombstone) }

  describe "#preserve?" do
    it "is not preserved" do
      expect(change_set.preserve?).to be false
    end
  end
end
