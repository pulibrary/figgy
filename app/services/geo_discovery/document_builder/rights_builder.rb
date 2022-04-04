# frozen_string_literal: true
module GeoDiscovery
  class DocumentBuilder
    class RightsBuilder
      attr_reader :resource_decorator

      def initialize(resource_decorator)
        @resource_decorator = resource_decorator
      end

      def build(document)
        document.rendered_rights_statement = resource_decorator.rendered_rights_statement&.first
      end
    end
  end
end
