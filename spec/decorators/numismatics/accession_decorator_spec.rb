# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::AccessionDecorator do
  subject(:decorator) { described_class.new(accession) }
  let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, numismatic_citation: numismatic_citation, firm_id: numismatic_firm.id, type: "gift", person_id: numismatic_person.id) }
  let(:numismatic_citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:numismatic_firm) { FactoryBot.create_for_repository(:numismatic_firm) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#formatted_date" do
    it "can handle hand-entered american style dates" do
      accession.date = "1/17/2007"
      expect { decorator.formatted_date }.not_to raise_error
    end

    it "can handle a single year or other unexpected string format" do
      accession.date = "2007"
      expect { decorator.formatted_date }.not_to raise_error
    end
  end

  describe "#label" do
    it "generates a label" do
      expect(decorator.label).to eq("1: 01/01/2001 gift name1 name2/firm name ($99.00)")
    end
  end

  describe "#title" do
    it "generates a title" do
      expect(decorator.title).to eq(["Accession 1: 01/01/2001 gift name1 name2/firm name ($99.00)"])
    end
  end

  describe "#citations" do
    it "renders the linked citations" do
      expect(decorator.citations).to eq(["short-title citation part citation number"])
    end
  end

  describe "#indexed_label" do
    it "renders a label for use in orangelight indexing" do
      expect(decorator.indexed_label).to eq("Accession number: 1, 2001-01-01, Gift of: name1 name2/firm name")
    end
  end

  context "when accession is not a gift" do
    let(:accession) { FactoryBot.create_for_repository(:numismatic_accession, numismatic_citation: numismatic_citation, firm_id: numismatic_firm.id, person_id: numismatic_person.id, type: "purchase") }
    it "renders a label without a gift of text" do
      expect(decorator.indexed_label).to eq("Accession number: 1, 2001-01-01, name1 name2/firm name")
    end
  end
end
