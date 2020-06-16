# frozen_string_literal: true
class CreateOcrRequestJob < ApplicationJob
  include ActiveStorage::Downloading

  def perform(file_path:)
    logger.info("Create OCR Request job initiated for: #{file_path}")
    return unless File.exist? file_path
    filename = File.basename file_path
    ocr_request = OcrRequest.new(filename: filename, state: "enqueued")
    ocr_request.save
    ocr_request.pdf.attach(io: File.open(file_path), filename: filename, content_type: "application/pdf")
    out_path = File.join(ocr_out_dir, filename)
    PdfOcrJob.perform_later(resource: ocr_request, out_path: out_path)
    File.delete(file_path)
  end

  def ocr_out_dir
    path = ENV["OCR_OUT_PATH"] || Rails.root.join("tmp", "ocr_out")
    FileUtils.mkdir_p(path) unless Dir.exist?(path)

    path
  end
end
