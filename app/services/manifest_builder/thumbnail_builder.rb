# frozen_string_literal: true
class ManifestBuilder
  # Builder Class for thumbnail resources within IIIF Presentation Manifests
  # @see http://iiif.io/api/presentation/2.1/#thumbnail
  class ThumbnailBuilder
    attr_reader :resource

    # Constructor
    # @param resource [Valkyrie::Resource] the Resource being viewed
    def initialize(resource)
      @resource = resource
    end

    # Adds the thumbnail URI to the Manifest object
    # @param manifest [IIIFManifest::ManifestBuilder::IIIFManifest] the manifest
    # @return [IIIFManifest::ManifestBuilder::IIIFManifest] the updated manifest
    def apply(manifest)
      manifest["thumbnail"] = thumbnail if thumbnail.present?
      manifest
    end

    private

      # Construct or retrieve the memoized ManifestHelper Object
      # @return [ManifestHelper]
      def helper
        @helper ||= ManifestHelper.new
      end

      # Generate the value Hash modeling the thumbnail resource for the Manifest
      # @see http://iiif.io/api/presentation/2.1/#resource-structure
      # @return [Hash, nil]
      def thumbnail
        return nil unless thumbnail_id && file_set && file_set.derivative_file
        {
          "@id" => helper.manifest_image_thumbnail_path(file_set.id),
          "service" => {
            "@context" => "http://iiiif.io/api/image/2/context.json",
            "@id" => helper.manifest_image_path(file_set),
            "profile" => "http;//iiiif.io/api/image/2/level2.json"
          }
        }
      end

      # Retrieve the FileSet Resource for the thumbnail
      # @return [FileSet, nil]
      def file_set
        @file_set ||= find_thumbnail_file_set(thumbnail_id)
      rescue Valkyrie::Persistence::ObjectNotFoundError
        return if resource.file_set_presenters.empty?
        @file_set ||= query_service.find_by(id: resource.file_set_presenters.first.id)
      end

      # Retrieve the FileSet resource for a given Valkyrie ID
      # @param record_id [Valkyrie::ID, String] the ID for the FileSet
      # @return [FileSet]
      def find_thumbnail_file_set(record_id)
        return unless record_id.present?
        record = query_service.find_by(id: Valkyrie::ID.new(record_id.to_s))
        if record.is_a?(FileSet)
          record
        else
          find_thumbnail_file_set(Array.wrap(record.thumbnail_id).first || Array.wrap(record.member_ids.first))
        end
      end

      # Retrieve the query service from the metadata adapter
      # @return [Valkyrie::Persistence::Postgres::QueryService]
      def query_service
        Valkyrie.config.metadata_adapter.query_service
      end

      # Retrieve the ID for the resource used as a thumbnail
      # @return [Valkyrie::ID]
      def thumbnail_id
        Array.wrap(resource.thumbnail_id).first
      end
  end
end
