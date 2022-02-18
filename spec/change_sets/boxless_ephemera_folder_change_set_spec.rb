# frozen_string_literal: true

require "rails_helper"

RSpec.describe BoxlessEphemeraFolderChangeSet do
  subject(:change_set) { described_class.new(FactoryBot.build(:ephemera_folder)) }

  it_behaves_like "an ephemera folder change set", described_class

  describe "#valid" do
    let(:valid_params) { {barcode: "", title: ["foo"], language: ["English"], page_count: [1], visibility: ["private"], rights_statement: RightsStatements.copyright_not_evaluated.to_s} }

    it "requires title, language, genre, page_count, visibility, and rights_statement" do
      expect(change_set.validate(valid_params)).to eq true
    end
  end

  describe "#barcode" do
    it "is not required" do
      expect(change_set.required?(:barcode)).to eq false
    end
  end

  describe "#folder_number" do
    it "is not required" do
      expect(change_set.required?(:folder_number)).to eq false
    end
  end

  describe "#height" do
    it "is not required" do
      expect(change_set.required?(:height)).to eq false
    end
  end

  describe "#width" do
    it "is not required" do
      expect(change_set.required?(:width)).to eq false
    end
  end
end
