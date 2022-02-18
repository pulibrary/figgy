# frozen_string_literal: true

class ManifestBuilder
  class SeeAlsoBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = resource
    end

    def apply(manifest)
      manifest["seeAlso"] = see_also
      manifest
    end

    private

      def see_also
        return figgy_rdf_hash unless resource.respond_to?(:source_metadata_identifier)
        source_metadata_hash.nil? ? figgy_rdf_hash : [figgy_rdf_hash, source_metadata_hash]
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
        return if resource.id.nil?
        {
          "@id" => helper.solr_document_url(id: resource.id, format: :jsonld),
          "format" => "application/ld+json"
        }
      end
  end
end
