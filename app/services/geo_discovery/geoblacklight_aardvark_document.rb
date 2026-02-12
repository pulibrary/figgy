require "json-schema"

module GeoDiscovery
  # Generates GeoBlacklight documents following the Aardvark schema.
  # @see https://opengeometadata.org/ogm-aardvark/
  class GeoblacklightAardvarkDocument < BaseDocument
    private

      def document_hash_required
        {
          id: slug,
          dct_title_s: title,
          gbl_resourceClass_sm: resource_class,
          dct_accessRights_s: rights,
          gbl_mdVersion_s: "Aardvark"
        }
      end

      def document_hash_optional
        {
          dct_description_sm: description.present? ? Array.wrap(description) : nil,
          dct_creator_sm: creator,
          dct_language_sm: Array.wrap(language),
          dct_publisher_sm: Array.wrap(publisher),
          dct_subject_sm: all_subject,
          dcat_theme_sm: subject,
          dct_spatial_sm: spatial,
          dct_temporal_sm: temporal,
          gbl_indexYear_im: [layer_year].compact,
          gbl_mdModified_dt: layer_modified,
          dct_references_s: clean_document(references).to_json.to_s,
          gbl_resourceType_sm: geom_types,
          dct_format_s: format,
          dct_issued_s: issued_year,
          gbl_suppressed_b: suppressed,
          dct_source_sm: source,
          dct_identifier_sm: identifier.present? ? [identifier] : nil,
          schema_provider_s: held_by&.first,
          locn_geometry: solr_coverage,
          dcat_bbox: solr_coverage,
          call_number_s: call_number,
          rights_statement_s: rendered_rights_statement
        }
      end

      def references
        {
          "http://schema.org/url" => url,
          "http://www.opengis.net/cat/csw/csdgm" => fgdc,
          "http://www.isotc211.org/schemas/2005/gmd/" => iso19139,
          "http://www.loc.gov/mods/v3" => mods,
          "http://schema.org/downloadUrl" => download,
          "http://schema.org/thumbnailUrl" => thumbnail,
          "http://iiif.io/api/image" => iiif,
          "http://iiif.io/api/presentation#manifest" => iiif_manifest,
          "http://www.opengis.net/def/serviceType/ogc/wmts" => wmts_path,
          "https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames" => xyz_path,
          "https://github.com/protomaps/PMTiles" => pmtiles_path,
          "https://github.com/cogeotiff/cog-spec" => cog_path
        }
      end

      def private_references
        {
          "http://schema.org/url" => url,
          "http://www.opengis.net/cat/csw/csdgm" => fgdc,
          "http://www.isotc211.org/schemas/2005/gmd/" => iso19139,
          "http://schema.org/thumbnailUrl" => thumbnail
        }
      end

      # Maps geometry types to Aardvark resource classes
      def resource_class
        classes = []
        classes << "Maps" if geom_types.include?("Image")
        classes << "Datasets" if (geom_types - ["Image"]).any?
        classes.presence || ["Datasets"]
      end

      # Extracts a 4-digit year from the issued string
      def issued_year
        return unless issued.present?
        match = issued.to_s.match(/(\d{4})/)
        match ? match[1] : nil
      end

      def schema
        JSON.parse(File.read(schema_path))
      end

      # Returns a path to the geoblackligh schema document
      # @return [String]
      def schema_path
        Rails.root.join("config", "discovery", "geoblacklight-schema-aardvark.json")
      end

      def valid?(doc)
        JSON::Validator.validate(schema, doc)
      end

      def schema_errors(doc)
        { error: JSON::Validator.fully_validate(schema, doc) }
      end
  end
end
