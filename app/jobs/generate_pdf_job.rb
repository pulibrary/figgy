# frozen_string_literal: true
class GeneratePDFJob < ApplicationJob
  delegate :query_service, to: :change_set_persister

  def perform(resource_id)
    resource = query_service.find_by(id: Valkyrie::ID.new(resource_id))
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
    ActionCable.server.broadcast("pdf_download_#{resource_id}", { pct_complete: 100, file_id: pdf_file.id.to_s, resource_id: resource_id })
  end

  private

    def change_set_persister
      ChangeSetPersister.default
    end
end
