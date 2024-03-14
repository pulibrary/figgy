# frozen_string_literal: true
class PDFService
  attr_reader :change_set_persister
  delegate :storage_adapter, to: :change_set_persister
  def initialize(change_set_persister)
    @change_set_persister = change_set_persister
  end

  def find_or_generate(change_set)
    pdf_file = change_set.resource.pdf_file

    unless pdf_file && binary_exists_for?(pdf_file)
      GeneratePDFJob.perform_later(change_set.resource.id.to_s)
    end

    pdf_file
  end

  private

    def binary_exists_for?(file_desc)
      pdf_file_binary = storage_adapter.find_by(id: file_desc.file_identifiers.first)
      !pdf_file_binary.nil?
    rescue Valkyrie::StorageAdapter::FileNotFound => error
      Valkyrie.logger.error("Failed to locate the file for the PDF FileMetadata: #{file_desc.file_identifiers.first}: #{error}")
      false
    end

    def query_service
      ChangeSetPersister.default.query_service
    end
end
