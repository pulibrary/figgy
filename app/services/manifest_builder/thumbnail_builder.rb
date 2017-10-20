# frozen_string_literal: true
class ManifestBuilder
  class ThumbnailBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = resource
    end

    def apply(manifest)
      manifest["thumbnail"] = thumbnail if thumbnail.present?
      manifest
    end

    private

      def helper
        @helper ||= ManifestHelper.new
      end

      def thumbnail
        return nil unless thumbnail_id
        {
          "@id" => helper.manifest_image_thumbnail_path(thumbnail_id),
          "service" => {
            "@context" => "http://iiiif.io/api/image/2/context.json",
            "@id" => helper.manifest_image_path(file_set),
            "profile" => "http;//iiiif.io/api/image/2/level2.json"
          }
        }
      end

      def file_set
        @file_set ||= query_service.find_by(id: thumbnail_id)
      end

      def query_service
        Valkyrie.config.metadata_adapter.query_service
      end

      def thumbnail_id
        Array.wrap(resource.thumbnail_id).first
      end
  end
end
