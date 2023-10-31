# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class RelationshipBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      def build(document)
        document.source = source
        document.suppressed = suppressed
      end

      private

        def parent?
          resource_decorator.parents.count.positive?
        end

        def parents
          resource_decorator.parents.map do |parent|
            SlugBuilder.new(parent.decorate).slug
          end
        end

        def scanned_map?
          resource_decorator.model.is_a?(ScannedMap)
        end

        def raster?
          resource_decorator.model.is_a?(RasterResource)
        end

        # Returns an array of parent document ids (slugs).
        # @return [Array] parent document slugs.
        def source
          return unless scanned_map? || raster?
          return unless parent?
          parents
        end

        # Documents with a parent work should be supressed.
        # @return [Boolean] should document be supressed?
        def suppressed
          return false if resource_decorator.model.gbl_suppressed_override == "1"
          return false unless scanned_map? || raster?
          return false unless parent?
          true
        end
    end
  end
end
