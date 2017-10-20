# frozen_string_literal: true
class ManifestBuilder
  class RenderingBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = RootNode.new(resource)
    end

    ##
    # Append the license to the IIIF Manifest
    # @param [IIIF::Presentation::Manifest] manifest the IIIF manifest being
    # @return [IIIF::Presentation::Manifest]
    def apply(manifest)
      manifest.rendering = rendering_hash if identifier?
      manifest
    end

    private

      def identifier?
        resource.decorate.identifier.present?
      end

      def identifier
        Array.wrap(resource.decorate.identifier).first
      end

      def rendering_hash
        {
          "@id" => "http://arks.princeton.edu/#{identifier}",
          "format" => "text/html"
        }
      end
  end
end
