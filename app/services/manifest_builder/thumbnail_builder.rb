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

      def nearest_member
        members = query_service.find_members(resource: resource, model: resource.resource.class)
        members.find { |member| member.thumbnail_id.present? }
      end

      def nearest_member_thumbnail_id
        return unless nearest_member
        @nearest_member_thumbnail_id ||= Array.wrap(nearest_member.thumbnail_id).first
      end

      def nearest_member_file_set
        member_file_set = find_thumbnail_file_set(nearest_member_thumbnail_id)
        return unless member_file_set&.derivative_file
        member_file_set
      rescue Valkyrie::Persistence::ObjectNotFoundError
        nil
      end

      # Generate the Hash for structuring thumbnail URIs
      # @see http://iiif.io/api/presentation/2.1/#resource-structure
      # @param file_set [FileSet]
      # @return [Hash]
      def build_thumbnail_values(file_set)
        {
          "@id" => helper.manifest_image_thumbnail_path(file_set),
          "service" => {
            "@context" => "http://iiif.io/api/image/2/context.json",
            "@id" => helper.manifest_image_path(file_set),
            "profile" => "http://iiif.io/api/image/2/level2.json"
          }
        }
      end

      # Determine whether or not the Resource has a FileSet (with a derivative file) referenced as a thumbnail
      # @return [TrueClass, FalseClass]
      def resource_has_thumbnail_file_set?
        thumbnail_id && file_set&.derivative_file&.image?
      end

      # Generate the value Hash modeling the thumbnail resource for the Manifest
      # @return [Hash, nil]
      def thumbnail
        member = resource_has_thumbnail_file_set? ? file_set : nearest_member_file_set
        return nil unless member
        build_thumbnail_values(member)
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
        return if record_id.blank?
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
