# frozen_string_literal: true

module GeoDiscovery
  class DocumentBuilder
    class SlugBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      def build(document)
        document.slug = slug
      end

      # Returns the document slug for use in discovery systems.
      # @return [String] document slug
      def slug
        identifier = Array.wrap(ark || resource_decorator.id.to_s).first
        id = identifier.gsub(%r(ark:/\d{5}/), "")
        "#{resource_decorator.held_by.first.parameterize}-#{id}"
      end

      private

        def ark
          identifier = resource_decorator.identifier.try(:first)
          identifier&.to_s
        end
    end
  end
end
