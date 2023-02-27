# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::CoinDecorator do
  subject(:decorator) { described_class.new(coin) }
  let(:coin) { FactoryBot.create_for_repository(:coin, numismatic_citation: numismatic_citation, numismatic_accession_id: numismatic_accession.id, loan: loan, provenance: provenance) }
  let(:numismatic_citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:numismatic_accession) { FactoryBot.create_for_repository(:numismatic_accession, accession_number: 234, person_id: numismatic_person.id) }
  let(:loan) { Numismatics::Loan.new(exhibit_name: "exhibit", note: "note", type: "type") }
  let(:provenance) { Numismatics::Provenance.new(date: "provenance date", note: "provenance note") }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "#citations" do
    it "renders the linked citations" do
      expect(decorator.citations).to eq(["short-title citation part citation number"])
    end
  end

  describe "#loan" do
    it "renders the linked loans" do
      expect(decorator.loan).to eq(["type, exhibit, note"])
    end
  end

  describe "#provenance" do
    it "renders the linked provenances" do
      expect(decorator.provenance).to eq(["provenance date; provenance note"])
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

  describe "#rendered_accession" do
    it "generates a label based on the accession's properties" do
      expect(decorator.rendered_accession).to eq("234: 2001-01-01 gift name1 name2 ($99.00)")
    end
  end

  describe "#pdf_file" do
    context "when there is a pdf and it exists" do
      before do
        allow(derivs).to receive(:find_by).with(id: file_id).and_return(file_id)
      end
      let(:derivs)   { Valkyrie::StorageAdapter.find(:derivatives) }
      let(:file_id)  { Valkyrie::ID.new("disk:///tmp/stubbed.tif") }
      let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: [file_id] }
      let(:coin) { FactoryBot.create_for_repository(:coin, file_metadata: [pdf_file]) }
      it "finds the pdf file" do
        expect(decorator.pdf_file).to eq pdf_file
      end
    end

    context "when there is a pdf but it does not exist" do
      before do
        allow(derivs).to receive(:find_by).with(id: file_id).and_raise(Valkyrie::StorageAdapter::FileNotFound)
      end
      let(:derivs)   { Valkyrie::StorageAdapter.find(:derivatives) }
      let(:file_id)  { Valkyrie::ID.new("disk:///tmp/stubbed.tif") }
      let(:pdf_file) { FileMetadata.new mime_type: "application/pdf", file_identifiers: [file_id] }
      let(:coin) { FactoryBot.create_for_repository(:coin, file_metadata: [pdf_file]) }
      it "does not return the bogus pdf file" do
        expect(decorator.pdf_file).to be nil
      end
    end

    context "when there is no pdf file" do
      let(:coin) { FactoryBot.create_for_repository(:coin) }
      it "returns nil" do
        expect(decorator.pdf_file).to be nil
      end
    end
  end
  describe "#pub_created_display" do
    context "when the coin is attached to a numismatic issue" do
      let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id], ruler_id: numismatic_person.id, denomination: ["1/2 Penny"]) }
      before do
        issue
      end
      it "returns a pub_created_display" do
        expect(decorator.pub_created_display).to eq("name1 name2 epithet (1868 to 1963), 1/2 Penny")
      end
    end
    context "when the coin is not attached to a numismatic issue" do
      it "will not error" do
        expect(decorator.pub_created_display).to be nil
      end
    end
  end
end
