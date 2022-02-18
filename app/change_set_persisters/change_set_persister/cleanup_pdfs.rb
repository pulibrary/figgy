# frozen_string_literal: true

# Remove stale PDFs from ScannedResources when the resource has changed
class ChangeSetPersister
  class CleanupPdfs
    attr_reader :resource, :change_set
    def initialize(change_set:, change_set_persister: nil, post_save_resource: nil)
      @change_set = change_set
      @resource = change_set.resource
    end

    def run
      return unless clean_up?

      # Return if the only update is that file metadata is being updated
      if change_set.changed.except("file_metadata", "created_file_sets").empty?
        # Delete the file metadata if the files cannot be located
        resource.file_metadata.delete(pdf_file) unless pdf_file_exists?
        return
      end

      resource.file_metadata.delete(pdf_file)
      CleanupFilesJob.perform_later(file_identifiers: [pdf_file_identifier.to_s]) unless pdf_file_identifier.nil?
    end

    private

      def clean_up?
        return false unless resource.is_a?(ScannedResource) || resource.is_a?(ScannedMap) || resource.is_a?(EphemeraFolder) || resource.is_a?(Numismatics::Coin)
        return false unless pdf_file
        true
      end

      def pdf_file
        @pdf_file ||= resource.pdf_file
      end

      def pdf_file_identifier
        @pdf_file_identifier ||= pdf_file.file_identifiers.first
      end

      def storage_adapter
        Valkyrie.config.storage_adapter
      end

      def pdf_file_exists?
        pdf_file_binary = storage_adapter.find_by(id: pdf_file_identifier)
        !pdf_file_binary.nil?
      rescue Valkyrie::StorageAdapter::FileNotFound => error
        Valkyrie.logger.error("Failed to locate the file for the PDF FileMetadata: #{pdf_file_identifier}: #{error}")
        false
      end
  end
end
