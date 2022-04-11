# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::CitationDecorator do
  subject(:decorator) { described_class.new(numismatic_citation) }
  let(:numismatic_citation) { Numismatics::Citation.new(part: "citation part", number: "citation number", numismatic_reference_id: [reference.id]) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference) }
  let(:issue) { FactoryBot.create_for_repository(:numismatic_issue, numismatic_citation: numismatic_citation) }

  before do
    reference
    numismatic_citation
    issue
  end

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#number" do
    it "rendersnumber as single value" do
      expect(decorator.number).to eq("citation number")
    end
  end

  describe "#numismatic_reference" do
    it "renders the linked numismatic reference as it's short-title" do
      expect(decorator.numismatic_reference).to eq("short-title")
    end
  end

  describe "#part" do
    it "renders part as single value" do
      expect(decorator.part).to eq("citation part")
    end
  end

  describe "#title" do
    it "renders the numismatic_citation title" do
      expect(decorator.title).to eq("short-title citation part citation number")
    end
  end
end
