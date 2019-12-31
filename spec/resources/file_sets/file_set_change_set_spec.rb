# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetChangeSet do
  subject(:change_set) { described_class.new(file_set) }

  let(:file_set) { FactoryBot.build(:file_set) }

  it_behaves_like "an optimistic locking change set"

  describe "#primary_terms" do
    it "is just the title and optimistic lock token" do
      expect(change_set.primary_terms).to eq [:title, :optimistic_lock_token]
    end
  end
end
