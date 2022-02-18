# frozen_string_literal: true

class ManifestBuilderV3
  # Builder Class for thumbnail resources within IIIF Presentation Manifests
  # @see https://iiif.io/api/presentation/3.0/#thumbnail
  class ThumbnailBuilder < ManifestBuilder::ThumbnailBuilder
    private

      # Generate the Hash for structuring thumbnail URIs
      # @param file_set [FileSet]
      # @return [Hash]
      def build_thumbnail_values(file_set)
        [
          {
            "id" => helper.manifest_image_thumbnail_path(file_set),
            "type" => "Image",
            "format" => "image/jpeg",
            "height" => 150
          }
        ]
      end

      # Construct or retrieve the memoized ManifestHelper Object
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end
  end
end
