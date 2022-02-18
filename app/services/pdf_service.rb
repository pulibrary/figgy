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
      pdf_file = PDFGenerator.new(resource: change_set.resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render
      change_set_persister.buffer_into_index do |buffered_changeset_persister|
        change_set.validate(file_metadata: [pdf_file])
        buffered_changeset_persister.save(change_set: change_set)
      end
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
end
