# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticAccessionDecorator do
  subject(:decorator) { described_class.new(accession) }
  let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, member_ids: [member_coin.id]) }
  let(:member_coin) { FactoryBot.create_for_repository(:coin) }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#members" do
    it "returns member references" do
      expect(decorator.members.map(&:id)).to eq [member_coin.id]
    end
  end
end
