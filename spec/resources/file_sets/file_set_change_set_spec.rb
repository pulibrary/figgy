# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSetChangeSet do
  subject(:change_set) { described_class.new(file_set) }

  let(:file_set) { FactoryBot.build(:file_set) }

  describe "#primary_terms" do
    it "is just the title" do
      expect(change_set.primary_terms).to eq [:title]
    end
  end

  describe "#remote_checksum" do
    let(:file_set) { FactoryBot.build(:file_set, remote_checksum: ["test"]) }

    it "accesses the remote checksum" do
      expect(change_set.remote_checksum).to eq "test"
    end
  end
end
