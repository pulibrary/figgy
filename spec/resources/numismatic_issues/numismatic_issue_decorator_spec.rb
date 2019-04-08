# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticIssueDecorator do
  subject(:decorator) { described_class.new(issue) }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id], state: "complete", numismatic_citation: numismatic_citation, numismatic_artist_ids: [artist.id]) }
  let(:coin) { FactoryBot.create_for_repository(:coin) }
  let(:numismatic_citation) { NumismaticCitation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:artist) { FactoryBot.create_for_repository(:numismatic_artist) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "#decorated_coins" do
    it "returns decorated member coins" do
      expect(decorator.decorated_coins.map(&:id)).to eq [coin.id]
    end
    it "provides a coin count" do
      expect(decorator.coin_count).to eq 1
    end
  end

  describe "#attachable_objects" do
    it "allows attaching coins" do
      expect(decorator.attachable_objects).to eq([Coin])
    end
  end

  describe "#numismatic_citations" do
    it "renders the linked numismatic_citations" do
      expect(decorator.numismatic_citations).to eq(["short-title citation part citation number"])
    end
  end

  describe "#artists" do
    it "renders the linked artists" do
      expect(decorator.artists).to eq(["artist person, artist role"])
    end
  end

  describe "state" do
    it "allows access to complete items" do
      expect(decorator.state).to eq("complete")
      expect(decorator.grant_access_state?).to be true
    end
  end

  describe "does not manage files or structure" do
    it "does not manage structure" do
      expect(decorator.manageable_structure?).to be false
    end
  end
end
