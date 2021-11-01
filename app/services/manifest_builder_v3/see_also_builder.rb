# frozen_string_literal: true
class ManifestBuilderV3
  # See: https://iiif.io/api/presentation/3.0/#seealso
  class SeeAlsoBuilder < ManifestBuilder::SeeAlsoBuilder
    private

      def source_metadata_hash
        return if resource.source_metadata_identifier.blank?
        {
          "id" => RemoteRecord.source_metadata_url(resource.source_metadata_identifier.first),
          "type" => "Dataset",
          "format" => "text/xml"
        }
      end

      def figgy_rdf_hash
        return if resource.id.nil?
        {
          "id" => helper.solr_document_url(id: resource.id, format: :jsonld),
          "type" => "Dataset",
          "format" => "application/ld+json"
        }
      end
  end
end
