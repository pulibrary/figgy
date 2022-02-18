# frozen_string_literal: true

class ManifestBuilderV3
  # See: https://iiif.io/api/presentation/3.0/#rights
  class RightsBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = RootNode.new(resource)
    end

    ##
    # Append the license to the IIIF Manifest
    # @param [IIIF::Presentation::Manifest] manifest
    # @return [IIIF::Presentation::Manifest]
    def apply(manifest)
      manifest["rights"] = rights if rights
      manifest
    end

    private

      def rights
        statements = resource.decorate.rights_statement.map(&:value)
        statements.empty? ? nil : statements.first
      end
  end
end
