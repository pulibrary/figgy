# frozen_string_literal: true

class CreateOcrRequestJob < ApplicationJob
  queue_as :high

  def perform(file_path:)
    logger.info("Create OCR Request job initiated for: #{file_path}")
    return unless File.exist? file_path
    filename = File.basename file_path
    ocr_request = OcrRequest.new(filename: filename, state: "Enqueued")
    ocr_request.save!
    ocr_request.pdf.attach(io: File.open(file_path), filename: filename, content_type: "application/pdf")
    PdfOcrJob.perform_later(resource: ocr_request)
    File.delete(file_path)
  end
end
