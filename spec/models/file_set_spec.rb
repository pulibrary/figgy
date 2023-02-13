# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSet do
  let(:shoulder) { "99999/fk4" }
  let(:blade) { "123456" }
  before do
    stub_ezid(shoulder: shoulder, blade: blade)
  end

  describe "optimistic locking" do
    it "is enabled" do
      expect(described_class.optimistic_locking_enabled?).to eq true
    end
  end

  describe "#primary_file" do
    context "when there is an original file" do
      it "returns that" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.OriginalFile)
        fm2 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.PreservationFile)
        fm3 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2, fm3])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is a preservation file and no original file" do
      it "returns the preservation file" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.PreservationFile)
        fm2 = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is only an intermediate file" do
      it "returns that" do
        fm = FileMetadata.new(use: Valkyrie::Vocab::PCDMUse.IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm])
        expect(fs.primary_file).to eq fm
      end
    end
  end

  describe "processing_status" do
    it "is a property" do
      expect(described_class.schema.key?(:processing_status)).to eq true
    end
  end
end
