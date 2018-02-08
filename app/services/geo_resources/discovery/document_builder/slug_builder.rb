# frozen_string_literal: true
module GeoResources
  module Discovery
    class DocumentBuilder
      class SlugBuilder
        attr_reader :resource_decorator

        def initialize(resource_decorator)
          @resource_decorator = resource_decorator
        end

        def build(document)
          document.slug = slug
        end

        private

          # Returns the document slug for use in discovery systems.
          # @return [String] document slug
          def slug
            identifier = Array.wrap(ark || resource_decorator.id.to_s).first
            id = identifier.gsub(%r(ark:/\d{5}/), '')
            "#{resource_decorator.provenance.first.parameterize}-#{id}"
          end

          def ark
            identifier = resource_decorator.identifier.try(:first)
            identifier.to_s if identifier
          end
      end
    end
  end
end
