# frozen_string_literal: true
require "rails_helper"

RSpec.describe NumismaticPersonDecorator do
  subject(:decorator) { described_class.new(numismatic_person) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }

  describe "manage files, order, and structure" do
    it "does not manage files, order, or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_order?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    context "with a born and died date" do
      it "generates a title" do
        expect(decorator.title).to eq("name1 name2 epithet (1868 - 1963)")
      end
    end

    context "with only years_active start and end dates" do
      let(:numismatic_person) do
        FactoryBot.create_for_repository(:numismatic_person,
                                         born: nil,
                                         died: nil,
                                         years_active_start: "1894",
                                         years_active_end: "1961")
      end

      it "generates a title" do
        expect(decorator.title).to eq("name1 name2 epithet (1894 - 1961)")
      end
    end
  end
end
