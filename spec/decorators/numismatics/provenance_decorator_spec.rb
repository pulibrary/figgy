# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ProvenanceDecorator do
  subject(:decorator) { described_class.new(provenance) }
  let(:firm) { FactoryBot.create_for_repository(:numismatic_firm) }
  let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:provenance) { Numismatics::Provenance.new(firm_id: firm.id, person_id: person.id, note: "note", date: "12/04/1999") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "renders the provenance title" do
      expect(decorator.title).to eq("firm name, firm city; name1 name2; 12/04/1999; note")
    end
  end
end
