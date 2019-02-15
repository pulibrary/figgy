# frozen_string_literal: true
require "rails_helper"

RSpec.describe CoinDecorator do
  subject(:decorator) { described_class.new(coin) }
  let(:coin) { FactoryBot.create_for_repository(:coin, numismatic_citation_ids: [citation.id], accession_number: accession.accession_number) }
  let(:citation) { FactoryBot.create_for_repository(:numismatic_citation, numismatic_reference_id: [reference.id]) }
  let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, accession_number: 234) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "state" do
    it "does not allow minting arks" do
      expect(decorator.ark_mintable_state?).to be false
    end
  end

  describe "#citations" do
    it "renders the linked citations" do
      expect(decorator.citations).to eq(["short-title citation part citation number"])
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

  describe "#accession_label" do
    it "generates a label based on the accession's properties" do
      expect(decorator.accession_label).to eq("234: 01/01/2001 gift Alice ($99.00)")
    end
  end
end
