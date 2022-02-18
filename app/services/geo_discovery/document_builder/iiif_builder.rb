# frozen_string_literal: true

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
            member_id = resource_decorator.thumbnail_id.try(:first)
            return nil unless member_id
            members = resource_decorator.geo_members.select { |m| m.id == member_id }
            members.first.decorate unless members.empty?
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

        # Returns a map set's representative file set decorator.
        # @return [FileSetDecorator] representative file set decorator
        def map_set_file_set
          @map_set_file_set ||= begin
            member_id = Array.wrap(resource_decorator.thumbnail_id).first
            return unless member_id
            member = query_service.find_by(id: member_id)
            return member.decorate if member&.is_a?(FileSet)
            member.decorate.geo_members.try(:first)
          end
        rescue Valkyrie::Persistence::ObjectNotFoundError
          nil
        end

        def query_service
          Valkyrie.config.metadata_adapter.query_service
        end
    end
  end
end
