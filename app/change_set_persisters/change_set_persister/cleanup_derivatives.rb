# frozen_string_literal: true

# Remove stale PDFs from ScannedResources when the resource has changed
class ChangeSetPersister
  class CleanupDerivatives
    attr_reader :resource, :change_set
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set = change_set
      @resource = change_set.resource
    end

    def run
      return unless resource.is_a?(ScannedResource) && pdf_file
      return if change_set.changed.except("file_metadata").empty?
      CleanupFilesJob.perform_later(file_identifiers: [pdf_file.file_identifiers.first.to_s])
      resource.file_metadata.delete(pdf_file)
    end

    private

      def pdf_file
        @pdf_file ||= resource.pdf_file
      end
  end
end
