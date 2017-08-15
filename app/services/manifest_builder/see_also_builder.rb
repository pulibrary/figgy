# frozen_string_literal: true
class ManifestBuilder
  class SeeAlsoBuilder
    attr_reader :resource

    ##
    # @param [Valhalla::Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = RootNode.new(resource)
    end

    def apply(manifest)
      manifest.see_also = see_also
      manifest
    end

    private

      def see_also
        source_metadata_hash.blank? ? figgy_rdf_hash : [figgy_rdf_hash, source_metadata_hash]
      end

      def source_metadata_hash
        return if resource.source_metadata_identifier.blank?
        {
          "@id" => RemoteRecord.source_metadata_url(resource.source_metadata_identifier.first),
          "format" => "text/xml"
        }
      end

      def helper
        @helper ||= ManifestHelper.new
      end

      def figgy_rdf_hash
        {
          "@id" => helper.polymorphic_url(resource, format: :jsonld),
          "format" => "application/ld+json"
        }
      end
  end
end
