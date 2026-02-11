module GeoDiscovery
  class DocumentBuilder
    class CompositeBuilder
      attr_reader :services

      def initialize(services)
        @services = services
      end

      # Runs each builder service to build a discovery document.
      # @param [BaseDocument] discovery document
      def build(document)
        services.each do |service|
          service.build(document)
        end
      end
    end
  end
end
