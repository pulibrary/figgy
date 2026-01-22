module GeoDiscovery
  class DocumentBuilder
    class IIIFBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      def build(document)
        document.iiif = iiif
        document.iiif_manifest = iiif_manifest
      end

      private

        # Gets the representative file set.
        # @return [FileSetDecorator] representative file set decorator
        def file_set
          geo_file_set || map_set_file_set
        end

        # Returns the representative geo file set decorator attached to work.
        # @return [FileSetDecorator] geo file set decorator
        def geo_file_set
          @geo_file_set ||= begin
            thumbnail_member_id = resource_decorator.thumbnail_id.try(:first)
            thumbnail_member = resource_decorator.geo_members.select { |m| m.id == thumbnail_member_id }&.first&.decorate
            return thumbnail_member if thumbnail_member
            resource_decorator.geo_members&.first&.decorate
          end
        end

        # Returns a map set's representative file set decorator.
        # @return [FileSetDecorator] representative file set decorator
        def map_set_file_set
          @map_set_file_set ||= begin
            thumbnail_member_id = resource_decorator.thumbnail_id.try(:first)
            thumbnail_member = resource_decorator.decorated_scanned_maps.select { |m| m.id == thumbnail_member_id }&.first
            if thumbnail_member
              thumbnail_member.geo_members&.first
            else
              scanned_map = resource_decorator.decorated_scanned_maps&.first
              scanned_map&.geo_members&.first
            end
          end
        end

        def helper
          @helper ||= ManifestBuilder::ManifestHelper.new
        end

        # Get IIIF image path for file set
        def iiif
          return unless manifestable? && file_set && iiif_path
          "#{iiif_path}/info.json"
        end

        # Get IIIF manifest path for resource
        def iiif_manifest
          return unless manifestable? && file_set
          manifest_path
        end

        def iiif_path
          helper.manifest_image_path(file_set)
        rescue Valkyrie::Persistence::ObjectNotFoundError
          nil
        end

        def manifest_path
          helper.manifest_url(resource_decorator)
        end

        def manifestable?
          resource_decorator.model.class.can_have_manifests?
        end
    end
  end
end
