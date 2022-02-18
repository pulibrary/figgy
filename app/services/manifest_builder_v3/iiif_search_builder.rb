# frozen_string_literal: true

class ManifestBuilderV3
  class IIIFSearchBuilder < ManifestBuilder::IIIFSearchBuilder
    def apply(manifest)
      return manifest unless resource.try(:search_enabled?)
      manifest["service"] ||= []
      manifest["service"] << search_service
      manifest
    end

    private

      def search_service
        {
          "id" => helper.solr_document_iiif_search_url(solr_document_id: resource.id.to_s),
          "type" => "SearchService1",
          "profile" => "https://iiif.io/api/search/1.0/"
        }
      end
  end
end
