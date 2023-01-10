# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestableAudioFile do
  let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_pm.wav") }
  let(:audio_file) { described_class.new(path: file_path) }

  context "with a preservation file" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_pm.wav") }

    describe "#original_filename" do
      it { expect(audio_file.original_filename.to_s).to eq "32101047382401_1_pm.wav" }
    end

    describe "#mime_type" do
      it { expect(audio_file.mime_type).to eq "audio/x-wav" }
    end

    describe "#content_type" do
      it { expect(audio_file.content_type).to eq "audio/x-wav" }
    end

    describe "#use" do
      it { expect(audio_file.use).to eq Valkyrie::Vocab::PCDMUse.PreservationFile }
    end

    describe "#preservation_file?" do
      it { expect(audio_file.preservation_file?).to eq true }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq false }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq false }
    end

    describe "#barcode_with_side" do
      it { expect(audio_file.barcode_with_side).to eq "32101047382401_1" }
    end

    describe "#is_a_part?" do
      it { expect(audio_file.is_a_part?).to be false }
    end

    describe "#barcode_with_side_and_part" do
      it { expect(audio_file.barcode_with_side_and_part).to eq "32101047382401_1" }
    end

    describe "#barcode" do
      it { expect(audio_file.barcode).to eq "32101047382401" }
    end

    describe "#side" do
      it { expect(audio_file.side).to eq "1" }
    end

    describe "#part" do
      it { expect(audio_file.part).to be nil }
    end
  end

  context "with an intermediate file" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_i.wav") }

    describe "#original_filename" do
      it { expect(audio_file.original_filename.to_s).to eq "32101047382401_1_i.wav" }
    end

    describe "#mime_type" do
      it { expect(audio_file.mime_type).to eq "audio/x-wav" }
    end

    describe "#content_type" do
      it { expect(audio_file.content_type).to eq "audio/x-wav" }
    end

    describe "#use" do
      it { expect(audio_file.use).to eq Valkyrie::Vocab::PCDMUse.IntermediateFile }
    end

    describe "#preservation_file?" do
      it { expect(audio_file.preservation_file?).to eq false }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq true }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq false }
    end

    describe "#barcode_with_side" do
      it { expect(audio_file.barcode_with_side).to eq "32101047382401_1" }
    end
  end
  context "with an access file" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_2_a.mp3") }

    describe "#original_filename" do
      it { expect(audio_file.original_filename.to_s).to eq "32101047382401_2_a.mp3" }
    end

    describe "#mime_type" do
      it { expect(audio_file.mime_type).to eq "audio/mpeg" }
    end

    describe "#content_type" do
      it { expect(audio_file.content_type).to eq "audio/mpeg" }
    end

    describe "#use" do
      it { expect(audio_file.use).to eq Valkyrie::Vocab::PCDMUse.ServiceFile }
    end

    describe "#preservation_file?" do
      it { expect(audio_file.preservation_file?).to eq false }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq false }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq true }
    end

    describe "#barcode_with_side" do
      it { expect(audio_file.barcode_with_side).to eq "32101047382401_2" }
    end
  end

  context "when preservation files have separate parts" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag4", "data", "32101047382492_1_p1_pm.wav") }

    describe "#barcode_with_side" do
      it { expect(audio_file.barcode_with_side).to eq "32101047382492_1" }
    end

    describe "#is_a_part?" do
      it { expect(audio_file.is_a_part?).to be true }
    end

    describe "#barcode_with_side_and_part" do
      it { expect(audio_file.barcode_with_side_and_part).to eq "32101047382492_1_p1" }
    end

    describe "#side" do
      it { expect(audio_file.side).to eq("1") }
    end

    describe "#part" do
      it { expect(audio_file.side).to eq("1") }
    end
  end
end
