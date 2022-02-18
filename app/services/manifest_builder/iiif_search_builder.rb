# frozen_string_literal: true

class ManifestBuilder
  class IIIFSearchBuilder
    attr_reader :resource

    ##
    # @param [Resource] resource the Resource being viewed
    def initialize(resource)
      @resource = resource
    end

    def apply(manifest)
      return manifest unless resource.try(:search_enabled?)
      manifest["service"] = search_service
      manifest
    end

    private

      def search_service
        {
          "@context" => "http://iiif.io/api/search/0/context.json",
          "@id" => helper.solr_document_iiif_search_url(solr_document_id: resource.id.to_s),
          "profile" => "http://iiif.io/api/search/0/search",
          "label" => "Search within this item"
        }
      end

      def helper
        @helper ||= ManifestBuilder::ManifestHelper.new
      end
  end
end
