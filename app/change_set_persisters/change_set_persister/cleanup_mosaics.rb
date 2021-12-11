# frozen_string_literal: true

# Remove stale mosaic documnets from RasterResources when the resource has changed
class ChangeSetPersister
  class CleanupMosaics
    attr_reader :resource, :change_set
    def initialize(change_set_persister: nil, change_set:, post_save_resource: nil)
      @change_set = change_set
      @resource = change_set.resource
    end

    def run
      return unless clean_up?

      # Return if the only update is that file metadata is being updated
      if change_set.changed.except("file_metadata", "created_file_sets").empty?
        # Delete the file metadata if the files cannot be located
        resource.file_metadata.delete(mosaic_file) unless mosaic_file_exists?
        return
      end

      resource.file_metadata.delete(mosaic_file)
      CleanupFilesJob.perform_later(file_identifiers: [mosaic_file_identifier.to_s]) unless mosaic_file_identifier.nil?
    end

    private

      def clean_up?
        return false unless resource.is_a?(RasterResource)
        return false unless mosaic_file
        true
      end

      def mosaic_file
        @mosaic_file ||= resource.mosaic_file
      end

      def mosaic_file_identifier
        @mosaic_file_identifier ||= mosaic_file.file_identifiers.first
      end

      def storage_adapter
        Valkyrie::StorageAdapter.find(:cloud_geo_derivatives)
      end

      def mosaic_file_exists?
        mosaic_file_binary = storage_adapter.find_by(id: mosaic_file_identifier)
        !mosaic_file_binary.nil?
      rescue Valkyrie::StorageAdapter::FileNotFound => error
        Valkyrie.logger.error("Failed to locate the file for the Mosaic FileMetadata: #{mosaic_file_identifier}: #{error}")
        false
      end
  end
end
