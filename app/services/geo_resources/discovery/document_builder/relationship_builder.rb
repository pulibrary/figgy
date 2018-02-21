# frozen_string_literal: true
module GeoResources
  module Discovery
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
            resource_decorator.is_a?(ScannedMap)
          end

          # Returns an array of parent document ids (slugs).
          # @return [Array] parent document slugs.
          def source
            return unless scanned_map? && parent?
            parents
          end

          # Documents with a parent work should be supressed.
          # @return [Boolean] should document be supressed?
          def suppressed
            return unless scanned_map? && parent?
            true
          end
      end
    end
  end
end
