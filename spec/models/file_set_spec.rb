# frozen_string_literal: true
require "rails_helper"

RSpec.describe FileSet do
  before do
    stub_ezid
  end

  describe "optimistic locking" do
    it "is enabled" do
      expect(described_class.optimistic_locking_enabled?).to eq true
    end
  end

  describe "#primary_file" do
    context "when there is an original file" do
      it "returns that" do
        fm = FileMetadata.new(use: ::PcdmUse::OriginalFile)
        fm2 = FileMetadata.new(use: ::PcdmUse::PreservationFile)
        fm3 = FileMetadata.new(use: ::PcdmUse::IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2, fm3])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is a preservation file and no original file" do
      it "returns the preservation file" do
        fm = FileMetadata.new(use: ::PcdmUse::PreservationFile)
        fm2 = FileMetadata.new(use: ::PcdmUse::IntermediateFile)
        fs = FactoryBot.build(:file_set, file_metadata: [fm, fm2])
        expect(fs.primary_file).to eq fm
      end
    end

    context "when there is only an intermediate file" do
      it "returns that" do
        fm = FileMetadata.new(use: ::PcdmUse::IntermediateFile)
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

  describe "#captions?", run_real_derivatives: true, run_real_characterization: true do
    it "returns true if there's an attached caption file" do
      resource = FactoryBot.create_for_repository(:scanned_resource_with_video_and_captions)
      file_set = Wayfinder.for(resource).file_sets.first

      expect(file_set.captions?).to eq true
    end
  end

  describe "#missing_captions?" do
    context "for a file set with just audio" do
      it "returns false" do
        resource = FactoryBot.create_for_repository(:audio_file_set)

        expect(resource.missing_captions?).to eq false
      end
    end
    context "for a file set with video and captions" do
      it "returns false" do
        resource = FactoryBot.create_for_repository(:video_file_set_with_caption)

        expect(resource.missing_captions?).to eq false
      end
    end
    context "for a file set and non-language captions" do
      it "returns true" do
        resource = FactoryBot.create_for_repository(:video_file_set_with_other_language_caption)

        expect(resource.missing_captions?).to eq true
      end
    end
    context "for a file set with video and no captions" do
      it "returns true" do
        resource = FactoryBot.create_for_repository(:video_file_set)

        expect(resource.missing_captions?).to eq true
      end
    end
  end
end
