# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticIssueDecorator do
  subject(:decorator) { described_class.new(issue) }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id], state: "complete") }
  let(:coin) { FactoryBot.create_for_repository(:coin) }

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
