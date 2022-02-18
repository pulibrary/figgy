# frozen_string_literal: true

class ManifestBuilder
  class RenderingBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = RootNode.new(resource)
    end

    ##
    # Append the license to the IIIF Manifest
    # @param [IIIF::Presentation::Manifest] manifest the IIIF manifest being
    # @return [IIIF::Presentation::Manifest]
    def apply(manifest)
      # This is currently here to work around https://github.com/iiif-prezi/osullivan/issues/56
      manifest["rendering"] = rendering_hash if identifier?
      manifest
    end

    private

      def identifier?
        resource.decorate.try(:identifier)
      end

      def identifier
        Array.wrap(resource.decorate.identifier).first
      end

      def rendering_hash
        {
          "@id" => Ark.new(identifier).uri,
          "format" => "text/html"
        }
      end
  end
end
