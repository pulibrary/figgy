# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::FirmDecorator do
  subject(:decorator) { described_class.new(numismatic_firm) }
  let(:numismatic_firm) { FactoryBot.create_for_repository(:numismatic_firm) }

  describe "manage files, order, and structure" do
    it "does not manage files, order, or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_order?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "generates a title" do
      expect(decorator.title).to eq("firm name, firm city")
    end
  end
end
