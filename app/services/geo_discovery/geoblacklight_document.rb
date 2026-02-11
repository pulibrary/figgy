require "json-schema"

module GeoDiscovery
  # For details on the schema,
  # @see 'https://github.com/geoblacklight/geoblacklight/wiki/Schema'
  class GeoblacklightDocument < BaseDocument
    private

      def document_hash_optional
        {
          dc_description_s: description,
          dc_creator_sm: creator,
          dc_language_s: language.try(:first),
          dc_publisher_s: publisher.try(:first),
          dc_subject_sm: subject,
          all_subject_sm: all_subject,
          dct_spatial_sm: spatial,
          dct_temporal_sm: temporal,
          solr_year_i: layer_year,
          layer_modified_dt: layer_modified,
          dct_references_s: clean_document(references).to_json.to_s,
          layer_geom_type_s: geom_types.first,
          layer_geom_type_sm: geom_types,
          dc_format_s: format,
          dct_issued_dt: issued,
          suppressed_b: suppressed,
          dc_source_sm: source,
          call_number_s: call_number,
          rights_statement_s: rendered_rights_statement
        }
      end

      def document_hash_required
        {
          geoblacklight_version: "1.0",
          dc_identifier_s: identifier,
          layer_slug_s: slug,
          uuid: slug,
          dc_title_s: title,
          solr_geom: solr_coverage,
          dct_provenance_s: held_by.first,
          dc_rights_s: rights
        }
      end

      # Dct references hash with download, WxS, and IIIF refs removed
      def private_references
        {
          "http://schema.org/url" => url,
          "http://www.opengis.net/cat/csw/csdgm" => fgdc,
          "http://www.isotc211.org/schemas/2005/gmd/" => iso19139,
          "http://schema.org/thumbnailUrl" => thumbnail
        }
      end

      # Builds the dct_references hash.
      # @return [Hash] geoblacklight references as a hash
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

      # Returns a path to the geoblackligh schema document
      # @return [String]
      def schema_path
        Rails.root.join("config", "discovery", "geoblacklight-schema.json")
      end
  end
end
