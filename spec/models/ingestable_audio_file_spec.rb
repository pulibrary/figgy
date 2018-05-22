# frozen_string_literal: true
require "rails_helper"

RSpec.describe IngestableAudioFile do
  let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_pm.wav") }
  let(:audio_file) { described_class.new(path: file_path) }

  context "with a preservation master file" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_pm.wav") }

    describe "#original_filename" do
      it { expect(audio_file.original_filename.to_s).to eq "32101047382401_1_pm.wav" }
    end

    describe "#mime_type" do
      it { expect(audio_file.mime_type).to eq "audio/wav" }
    end

    describe "#content_type" do
      it { expect(audio_file.content_type).to eq "audio/wav" }
    end

    describe "#use" do
      it { expect(audio_file.use).to eq Valkyrie::Vocab::PCDMUse.PreservationMasterFile }
    end

    describe "#master?" do
      it { expect(audio_file.master?).to eq true }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq false }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq false }
    end

    describe "#barcode_with_part" do
      it { expect(audio_file.barcode_with_part).to eq "32101047382401_1" }
    end
  end

  context "with an intermediate file" do
    let(:file_path) { Rails.root.join("spec", "fixtures", "av", "la_c0652_2017_05_bag", "data", "32101047382401_1_i.wav") }

    describe "#original_filename" do
      it { expect(audio_file.original_filename.to_s).to eq "32101047382401_1_i.wav" }
    end

    describe "#mime_type" do
      it { expect(audio_file.mime_type).to eq "audio/wav" }
    end

    describe "#content_type" do
      it { expect(audio_file.content_type).to eq "audio/wav" }
    end

    describe "#use" do
      it { expect(audio_file.use).to eq Valkyrie::Vocab::PCDMUse.IntermediateFile }
    end

    describe "#master?" do
      it { expect(audio_file.master?).to eq false }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq true }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq false }
    end

    describe "#barcode_with_part" do
      it { expect(audio_file.barcode_with_part).to eq "32101047382401_1" }
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

    describe "#master?" do
      it { expect(audio_file.master?).to eq false }
    end

    describe "#intermediate?" do
      it { expect(audio_file.intermediate?).to eq false }
    end

    describe "#access?" do
      it { expect(audio_file.access?).to eq true }
    end

    describe "#barcode_with_part" do
      it { expect(audio_file.barcode_with_part).to eq "32101047382401_2" }
    end
  end
end
