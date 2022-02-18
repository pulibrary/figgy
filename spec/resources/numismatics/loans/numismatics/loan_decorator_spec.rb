# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::LoanDecorator do
  subject(:decorator) { described_class.new(loan) }
  let(:firm) { FactoryBot.create_for_repository(:numismatic_firm) }
  let(:person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:loan) { Numismatics::Loan.new(firm_id: firm.id, person_id: person.id, exhibit_name: "exhibit", note: "note", type: "type") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#firm" do
    it "renders the loan firm" do
      expect(decorator.firm).to eq("firm name, firm city")
    end
  end

  describe "#person" do
    it "renders the loan person" do
      expect(decorator.person).to eq("name1 name2")
    end
  end

  describe "#title" do
    it "renders the loan title" do
      expect(decorator.title).to eq("type, exhibit, note")
    end
  end
end
