# frozen_string_literal: true
class PdfOcrJob < ApplicationJob
  include ActiveStorage::Downloading
  attr_reader :blob, :out_path, :resource

  def perform(resource:, out_path:)
    @resource = resource
    @out_path = out_path
    @blob = resource.pdf # Required for ActiveStorage blob to tempfile method.
    update_state(state: "Processing")
    return unless pdf_attached?
    run_ocr_pdf
    update_state(state: "Complete")
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
      return if status.success?
      message = "PDF OCR job failed: #{error_str}"
      update_state(state: "Error", message: message)
      raise message unless status.success?
    end
  end

  def update_state(state:, message: nil)
    resource.state = state
    resource.note = message if message
    resource.save
  end
end
