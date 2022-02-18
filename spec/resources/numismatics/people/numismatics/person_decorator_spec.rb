# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::PersonDecorator do
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
        expect(decorator.title).to eq("name1 name2 epithet (1868 to 1963)")
      end
    end

    context "with only a died date" do
      let(:numismatic_person) do
        FactoryBot.create_for_repository(:numismatic_person,
          born: nil,
          died: "1963",
          years_active_start: nil,
          years_active_end: nil)
      end

      it "generates a title" do
        expect(decorator.title).to eq("name1 name2 epithet ( to 1963)")
      end
    end

    context "with only a years_active_start date" do
      let(:numismatic_person) do
        FactoryBot.create_for_repository(:numismatic_person,
          born: nil,
          died: nil,
          years_active_start: "1894",
          years_active_end: nil)
      end

      it "generates a title" do
        expect(decorator.title).to eq("name1 name2 epithet (1894 to )")
      end
    end
  end
end
