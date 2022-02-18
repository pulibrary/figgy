# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::SubjectDecorator do
  subject(:decorator) { described_class.new(numismatic_subject) }
  let(:numismatic_subject) { Numismatics::Subject.new(type: "Animal", subject: "unicorn") }

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#title" do
    it "renders the numismatic_subject title" do
      expect(decorator.title).to eq("Animal, unicorn")
    end
  end
end
