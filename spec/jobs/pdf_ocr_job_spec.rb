# frozen_string_literal: true
require "rails_helper"

RSpec.describe PdfOcrJob do
  describe "#perform" do
    let(:out_dir) { Figgy.config["ocr_out_path"] }
    let(:out_path) { File.join(out_dir, "ocr-sample.pdf") }
    let(:resource) { FactoryBot.create(:ocr_request, file: fixture_path) }

    before do
      # Create tmp ocr out directory
      FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)
    end

    after do
      # Cleanup PDFs
      File.delete(out_path) if File.exist?(out_path)
    end

    context "with a valid PDF" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }

      it "creates on OCRed PDF in an output directory and deletes the attached PDF" do
        expect { described_class.perform_now(resource: resource, out_path: out_path) }
          .to change { File.exist?(out_path) }
          .from(false).to(true)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Complete"
        expect(ocr_request.pdf.attached?).to be false
      end
    end

    context "with an invalid PDF" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "bad.pdf") }

      it "raises an exception and does not delete the attached PDF" do
        expect { described_class.perform_now(resource: resource, out_path: out_path) }
          .to raise_error(/PDF OCR job failed/)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Error"
        expect(ocr_request.note).to include "PDF OCR job failed"
        expect(ocr_request.pdf.attached?).to be true
      end
    end

    context "with an no attached PDF" do
      let(:resource) { FactoryBot.create(:ocr_request) }

      it "adds an error message to the ocr request resource" do
        described_class.perform_now(resource: resource, out_path: out_path)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Error"
        expect(ocr_request.note).to include "Resource has no attached PDF"
      end
    end
  end
end
