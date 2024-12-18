# frozen_string_literal: true
require "rails_helper"

RSpec.describe PdfOcrJob do
  describe "#perform" do
    let(:ssh_session) { instance_double(Net::SSH::Connection::Session) }
    let(:sftp_session) { instance_double(Net::SFTP::Session) }
    let(:resource) { FactoryBot.create(:ocr_request, file: fixture_path) }

    before do
      allow(Net::SFTP).to receive(:start).and_return(sftp_session)
      allow(sftp_session).to receive(:upload!)
      allow(sftp_session).to receive(:close_channel)
      allow(sftp_session).to receive(:session).and_return(ssh_session)
      allow(ssh_session).to receive(:close)
    end

    context "with a valid PDF" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "sample.pdf") }

      it "creates on OCRed PDF, uploads the file to the Illiad SFTP server, and deletes the attached PDF" do
        described_class.perform_now(resource: resource)
        expect(sftp_session).to have_received(:upload!)
        expect(sftp_session).to have_received(:close_channel)
        expect(ssh_session).to have_received(:close)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Complete"
        expect(ocr_request.pdf.attached?).to be false
      end
    end

    context "with a PDF that can't be OCRed" do
      let(:fixture_path) { Rails.root.join("spec", "fixtures", "files", "bad.pdf") }

      it "saves error on the ocr request resource and uploads the original file to the Illiad SFTP server" do
        described_class.perform_now(resource: resource)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Error"
        expect(ocr_request.note).to include "PDF OCR job failed"
        expect(sftp_session).to have_received(:upload!)
        expect(ocr_request.pdf.attached?).to be false
      end
    end

    context "with an no attached PDF" do
      let(:resource) { FactoryBot.create(:ocr_request) }

      it "adds an error message to the ocr request resource" do
        described_class.perform_now(resource: resource)
        ocr_request = OcrRequest.all.first
        expect(ocr_request.state).to eq "Error"
        expect(ocr_request.note).to include "Resource has no attached PDF"
      end
    end
  end
end
