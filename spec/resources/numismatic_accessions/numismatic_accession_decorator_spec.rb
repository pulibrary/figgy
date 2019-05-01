# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticAccessionDecorator do
  subject(:decorator) { described_class.new(accession) }
  let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, numismatic_citation: numismatic_citation, firm_id: numismatic_firm.id, person_id: numismatic_person.id) }
  let(:numismatic_citation) { NumismaticCitation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:numismatic_firm) { FactoryBot.create_for_repository(:numismatic_firm) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#label" do
    it "generates a label" do
      expect(decorator.label).to eq("1: 01/01/2001 gift name1 name2/firm name ($99.00)")
    end
  end

  describe "#citations" do
    it "renders the linked citations" do
      expect(decorator.citations).to eq(["short-title citation part citation number"])
    end
  end
end
