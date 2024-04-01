# frozen_string_literal: true
class PDFService
  attr_reader :change_set_persister
  delegate :storage_adapter, to: :change_set_persister
  def initialize(change_set_persister)
    @change_set_persister = change_set_persister
  end

  def find_or_generate(resource_id:)
    resource = query_service.find_by(id: resource_id)
    pdf_file = resource.pdf_file

    unless pdf_file && binary_exists_for?(pdf_file)
      pdf_file = PDFGenerator.new(resource: resource, storage_adapter: Valkyrie::StorageAdapter.find(:derivatives)).render

      begin
        # Reload the resource and change set to comply with optimistic locking
        resource = query_service.find_by(id: resource.id)
        change_set = ChangeSet.for(resource)
        change_set_persister.buffer_into_index do |buffered_changeset_persister|
          change_set.validate(file_metadata: [pdf_file])
          buffered_changeset_persister.save(change_set: change_set)
          # rubocop:disable Lint/SuppressedException
        rescue
          # If a user initiatves PDF generation, waits, then gives up and tries again,
          # the second one may fail because the first one successfully generated the PDF
          # and then saved before the second one did. Just serve the generated PDF.
          # This might also fail because of Read Only - we never want to prevent
          # the user getting the PDF even if we can't cache it, so just always
          # serve it.
        end
        # rubocop:enable Lint/SuppressedException
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

    def query_service
      ChangeSetPersister.default.query_service
    end
end
