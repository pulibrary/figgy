# frozen_string_literal: true

class PdfOcrJob < ApplicationJob
  queue_as :high
  attr_reader :blob, :resource

  def perform(resource:)
    logger.info("PDF OCR job initiated for: #{resource.filename}")
    @resource = resource
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
    blob.open do |file|
      _stdout_str, error_str, status = Open3.capture3("ocrmypdf", "--force-ocr", "--rotate-pages", "--deskew", file.path, temporary_file.path.to_s)
      if status.success?
        transfer_file(temporary_file.path.to_s)
        true
      else
        update_state(state: "Error", message: "PDF OCR job failed: #{error_str}")
        transfer_file(file.path)
        false
      end
    end
  end

  def update_state(state:, message: nil)
    resource.state = state
    resource.note = message if message
    resource.save
  end

  def temporary_file
    @temporary_file ||= Tempfile.new
  end

  def transfer_file(path)
    host = Figgy.config["illiad_sftp_host"]
    user = Figgy.config["illiad_sftp_user"]
    pass = Figgy.config["illiad_sftp_pass"]
    port = Figgy.config["illiad_sftp_port"]
    out_path = File.join(Figgy.config["illiad_sftp_path"], "pdf", resource.filename)

    begin
      sftp = Net::SFTP.start(host, user, { password: pass, port: port })
      sftp.upload!(path, out_path)
    ensure
      sftp.close_channel
      sftp.session.close
    end
  end
end
