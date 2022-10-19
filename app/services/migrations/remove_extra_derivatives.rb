# frozen_string_literal: true

module Migrations
  class RemoveExtraDerivatives
    def self.call
      new.run
    end

    def run
      progress_bar
      query_service.find_all_of_model(model: RasterResource).each do |resource|
        Wayfinder.for(resource).file_sets.each do |file_set|
          next unless extra_thumbnails?(file_set)

          RegenerateDerivativesJob.perform_later(file_set.id.to_s)
        end
        progress_bar.progress += 1
      end
    end

    private

      def progress_bar
        @progress_bar ||= ProgressBar.create format: "%a %e %P% Resources Processed: %c of %C", total: query_service.custom_queries.count_all_of_model(model: RasterResource)
      end

      # we only check for extra thumbnails because lots of resources might have
      # extra derivatives (one jp2 and one tiff) from when we migrated to
      # pyramidal tiffs, and the bug we're cleaning up from was failing after
      # generating both the derivative and the thumbnail
      def extra_thumbnails?(file_set)
        file_set.file_metadata.count(&:thumbnail_file?) > 1
      end

      def query_service
        @query_service ||= Valkyrie.config.metadata_adapter.query_service
      end
  end
end
