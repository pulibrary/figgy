# frozen_string_literal: true
require "rails_helper"

RSpec.describe PdfOcrJob do
  describe "#perform" do
    with_queue_adapter :inline
    let(:in_path) { Rails.root.join("tmp", "sample.pdf") }
    let(:out_path) { Rails.root.join("tmp", "ocr-sample.pdf") }

    before do
      # Copy pdf fixture to input directory
      FileUtils.cp(fixture_path, in_path)

      # Mock lsof command to reduce spec run times
      allow(Open3).to receive(:capture3).and_call_original
      allow(Open3).to receive(:capture3).with("lsof", in_path.to_s).and_return(lsof_response)
    end

    after do
      # Cleanup PDFs
      File.delete(in_path) if File.exist?(in_path)
      File.delete(out_path) if File.exist?(out_path)
    end

    context "with a valid PDF" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }
      let(:lsof_response) { ["", "", nil] }

      it "creates on OCRed PDF in an output directory and deletes the original PDF" do
        expect { described_class.perform_now(in_path: in_path, out_path: out_path) }
          .to change { File.exist?(out_path) }
          .from(false).to(true)
        expect(File.exist?(in_path)).to be false
      end
    end

    context "with an invalid PDF" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "bad.pdf") }
      let(:lsof_response) { ["", "", nil] }

      it "raises an exception and does not delete the original PDF" do
        expect { described_class.perform_now(in_path: in_path, out_path: out_path) }
          .to raise_error(/PDF OCR job failed/)
        expect(File.exist?(in_path)).to be true
      end
    end

    context "when a PDF is not released by another process within the max_wait timeframe" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "bad.pdf") }
      let(:lsof_response) { ["busy", "", nil] }

      before do
        described_class.max_wait = 1
        described_class.sleep_interval = 1
      end

      it "raises an exception" do
        expect { described_class.perform_now(in_path: in_path, out_path: out_path) }
          .to raise_error(/PDF OCR job failed: Timed out/)
      end
    end

    context "when the lsof command returns an error" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "bad.pdf") }
      let(:lsof_response) { ["", "error", nil] }

      it "raises an exception" do
        expect { described_class.perform_now(in_path: in_path, out_path: out_path) }
          .to raise_error(/PDF OCR job failed/)
      end
    end
  end
end
