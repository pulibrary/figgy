# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticProvenanceDecorator do
  subject(:decorator) { described_class.new(provenance) }
  let(:firm) { FactoryBot.create_for_repository(:numismatic_firm) }
  let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:provenance) { NumismaticProvenance.new(firm_id: firm.id, person_id: person.id, note: "note", date: "12/04/1999") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#firm" do
    it "renders the provenance firm" do
      expect(decorator.firm).to eq("name, city")
    end
  end

  describe "#person" do
    it "renders the provenance person" do
      expect(decorator.person).to eq("name1 name2")
    end
  end

  describe "#title" do
    it "renders the provenance title" do
      expect(decorator.title).to eq("note, 12/04/1999")
    end
  end
end
