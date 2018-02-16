# frozen_string_literal: true
module GeoResources
  module Discovery
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
          # @return [FileSet] representative file set
          def file_set
            @file_set ||= begin
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
            return unless manifestable? && file_set
            "#{iiif_path}/info.json"
          end

          # Get IIIF manifest path for resource
          def iiif_manifest
            return unless manifestable? && file_set
            manifest_path
          end

          def iiif_path
            helper.manifest_image_path(file_set)
          end

          def manifest_path
            helper.manifest_url(resource_decorator)
          end

          def manifestable?
            resource_decorator.model_name == 'ScannedMap'
          end
      end
    end
  end
end
