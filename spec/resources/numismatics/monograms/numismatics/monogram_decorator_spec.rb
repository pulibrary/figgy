# frozen_string_literal: true

require "rails_helper"

RSpec.describe Numismatics::MonogramDecorator do
  subject(:decorator) { described_class.new(monogram) }
  let(:monogram) { FactoryBot.create_for_repository(:numismatic_monogram, member_ids: [file_set.id]) }
  let(:file_set) { FactoryBot.create_for_repository(:file_set, title: ["File Set 5"]) }

  describe "#attachable_objects" do
    it "does not allow attaching objects" do
      expect(decorator.attachable_objects).to eq([])
    end
  end

  describe "manage files and structure" do
    it "manages files but not structure" do
      expect(decorator.manageable_files?).to be true
      expect(decorator.manageable_structure?).to be false
    end
  end

  describe "#members" do
    it "returns file_sets" do
      expect(decorator.members.map(&:id)).to eq [file_set.id]
    end
  end

  describe "#decorated_file_sets" do
    it "returns decorated file_sets" do
      expect(decorator.decorated_file_sets.first).to be_a(FileSetDecorator)
      expect(decorator.decorated_file_sets.map(&:id)).to eq [file_set.id]
    end
  end

  describe "#title" do
    it "renders title as single value" do
      expect(decorator.title).to eq("Test Monogram")
    end
  end

  describe "#decorated_filename" do
    it "adds the filename" do
      expect(decorator.decorated_filename).to eq("File Set 5")
    end
  end

  describe "order manager" do
    it "will not use order manager" do
      expect(decorator.manageable_order?).to be false
    end
  end
end
