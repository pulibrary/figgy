# frozen_string_literal: true
require "active_storage/downloading"

class CreateOcrRequestJob < ApplicationJob
  include ActiveStorage::Downloading
  queue_as :high

  def perform(file_path:)
    logger.info("Create OCR Request job initiated for: #{file_path}")
    return unless File.exist? file_path
    filename = File.basename file_path
    ocr_request = OcrRequest.new(filename: filename, state: "Enqueued")
    ocr_request.save
    ocr_request.pdf.attach(io: File.open(file_path), filename: filename, content_type: "application/pdf")
    out_path = File.join(ocr_out_dir, filename)
    PdfOcrJob.perform_later(resource: ocr_request, out_path: out_path)
    File.delete(file_path)
  end

  def ocr_out_dir
    out_dir = Figgy.config["ocr_out_path"]
    FileUtils.mkdir_p(out_dir) unless File.directory?(out_dir)

    out_dir
  end
end
