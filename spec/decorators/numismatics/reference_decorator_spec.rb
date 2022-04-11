# frozen_string_literal: true
require "rails_helper"

RSpec.describe Numismatics::ReferenceDecorator do
  subject(:decorator) { described_class.new(reference) }
  let(:reference) { FactoryBot.create_for_repository(:numismatic_reference, year: 2020, author_id: numismatic_person.id, member_ids: [child_reference.id]) }
  let(:numismatic_person) { FactoryBot.create_for_repository(:numismatic_person) }
  let(:child_reference) { FactoryBot.create_for_repository(:numismatic_reference) }

  describe "#attachable_objects" do
    it "allows attaching numismatic references" do
      expect(decorator.attachable_objects).to eq([Numismatics::Reference])
    end
  end

  describe "manage files and structure" do
    it "does not manage files or structure" do
      expect(decorator.manageable_files?).to be false
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#authors" do
    it "renders short title as single value" do
      expect(decorator.authors).to eq(["name1 name2"])
    end
  end

  describe "#indexed_title" do
    it "renders indexed title as single value" do
      expect(decorator.indexed_title).to eq("short-title, name1 name2, Test Reference, 2020")
    end
  end

  describe "#members" do
    it "returns member references" do
      expect(decorator.members.map(&:id)).to eq [child_reference.id]
    end
  end

  describe "#short_title" do
    it "renders short title as single value" do
      expect(decorator.short_title).to eq("short-title")
    end
  end

  describe "#title" do
    it "renders short title as single value" do
      expect(decorator.title).to eq("Test Reference")
    end
  end
end
