# frozen_string_literal: true
require "rails_helper"

RSpec.describe CoinDecorator do
  subject(:decorator) { described_class.new(coin) }
  let(:coin) { FactoryBot.create_for_repository(:coin, references: [proxy]) }
  let(:proxy) { ProxyNumismaticReference.new numismatic_reference_id: [reference.id] }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "state" do
    it "does not allow minting arks" do
      expect(decorator.ark_mintable_state?).to be false
    end
  end

  describe "#proxies" do
    it "renders the linked citations" do
      expect(decorator.references.first.to_s).to eq(["short-title, citation part citation number"])
    end
  end

  describe "manages files but not structure" do
    it "manages files" do
      expect(decorator.manageable_files?).to be true
    end
    it "orders files" do
      expect(decorator.orderable_files?).to be true
    end
    it "does not manage structure" do
      expect(decorator.manageable_structure?).to be false
    end
  end
end
