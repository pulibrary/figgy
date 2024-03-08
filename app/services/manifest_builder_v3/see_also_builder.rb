# frozen_string_literal: true
class ManifestBuilderV3
  # See: https://iiif.io/api/presentation/3.0/#seealso
  class SeeAlsoBuilder < ManifestBuilder::SeeAlsoBuilder
    def apply(manifest)
      manifest["seeAlso"] = see_also
      manifest
    end

    private

      def see_also
        return [figgy_rdf_hash] unless resource.respond_to?(:source_metadata_identifier)
        source_metadata_hash.nil? ? [figgy_rdf_hash] : [figgy_rdf_hash, source_metadata_hash]
      end

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
