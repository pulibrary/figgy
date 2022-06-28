# frozen_string_literal: true
require 'active_storage/downloading'

class PdfOcrJob < ApplicationJob
  include ActiveStorage::Downloading
  queue_as :high
  attr_reader :blob, :out_path, :resource

  def perform(resource:, out_path:)
    logger.info("PDF OCR job initiated for: #{resource.filename}")
    @resource = resource
    @out_path = out_path
    @blob = resource.pdf # Required for ActiveStorage blob to tempfile method.
    update_state(state: "Processing")
    return unless pdf_attached?
    update_state(state: "Complete") if run_pdf_ocr
    # Delete original PDF
    resource.pdf.purge
  end

  def pdf_attached?
    return true if resource.pdf.attached?
    update_state(state: "Error", message: "Resource has no attached PDF.")
    false
  end

  def run_pdf_ocr
    download_blob_to_tempfile do |file|
      _stdout_str, error_str, status = Open3.capture3("ocrmypdf", "--force-ocr", "--rotate-pages", "--deskew", file.path, out_path.to_s)
      return true if status.success?
      update_state(state: "Error", message: "PDF OCR job failed: #{error_str}")

      # Copy orginal file to destination without OCR
      FileUtils.cp file.path, out_path.to_s
    end

    false
  end

  def update_state(state:, message: nil)
    resource.state = state
    resource.note = message if message
    resource.save
  end
end
