# frozen_string_literal: true
require "rails_helper"

RSpec.describe CoinDecorator do
  subject(:decorator) { described_class.new(coin) }
  let(:coin) { FactoryBot.create_for_repository(:coin, citation: citation, accession_number: accession.accession_number) }
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
      let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, member_ids: [coin.id], ruler: ["George I"], denomination: ["1/2 Penny"]) }
      before do
        issue
      end
      it "returns a pub_created_display" do
        expect(decorator.pub_created_display).to eq("George I, 1/2 Penny")
      end
    end
    context "when the coin is not attached to a numismatic issue" do
      it "will not error" do
        expect(decorator.pub_created_display).to be nil
      end
    end
  end
end
