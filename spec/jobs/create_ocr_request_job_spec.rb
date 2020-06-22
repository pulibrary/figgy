# frozen_string_literal: true
require "rails_helper"

RSpec.describe CreateOcrRequestJob do
  describe "#perform" do
    let(:in_dir) { Figgy.config["ocr_in_path"] }
    let(:in_path) { File.join(in_dir, "sample.pdf") }
    let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }

    before do
      allow(PdfOcrJob).to receive(:perform_later)

      # Create tmp ocr in directory
      FileUtils.mkdir_p(in_dir) unless File.directory?(in_dir)

      # Copy fixture to in directory
      FileUtils.cp(fixture_path, in_path)
    end

    after do
      # Cleanup files
      File.delete(in_path) if File.exist?(in_path)
    end

    it "creates an OcrRequest resource and deletes the original file" do
      expect { described_class.perform_now(file_path: in_path) }
        .to change { File.exist?(in_path) }
        .from(true).to(false)
      ocr_request = OcrRequest.all.first
      expect(ocr_request.filename).to eq "sample.pdf"
      expect(ocr_request.state).to eq "Enqueued"
      expect(ocr_request.pdf.attached?).to be true
      expect(PdfOcrJob).to have_received(:perform_later)
    end
  end
end
