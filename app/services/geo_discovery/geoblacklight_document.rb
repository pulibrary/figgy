# frozen_string_literal: true
require "json-schema"

module GeoDiscovery
  # For details on the schema,
  # @see 'https://github.com/geoblacklight/geoblacklight/wiki/Schema'
  class GeoblacklightDocument < AbstractDocument
    # Implements the to_hash method on the abstract document.
    # @param _args [Array<Object>] arguments needed for the renderer, unused here
    # @return [Hash] geoblacklight document as a hash
    def to_hash(_args = nil)
      return document unless build_private_document?
      private_document
    end

    # Implements the to_json method on the abstract document.
    # @param _args [Array<Object>] arguments needed for the json renderer, unused here
    # @return [String] geoblacklight document as a json string
    def to_json(_args = nil)
      return document.to_json unless build_private_document?
      private_document.to_json
    end

    private

      # Cleans the geoblacklight document hash by removing unused fields,
      # then validates it again a json schema. If there are errors, an
      # error hash is returned, otherwise, the cleaned doc is returned.
      # @return [Hash] geoblacklight document hash or error hash
      def document
        clean = clean_document(document_hash)
        if valid?(clean)
          clean
        else
          schema_errors(clean)
        end
      end

      # Builds the geoblacklight document hash.
      # @return [Hash] geoblacklight document as a hash
      def document_hash
        document_hash_required.merge(document_hash_optional)
      end

      # rubocop:disable Metrics/MethodLength
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
          layer_id_s: layer_id,
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
      # rubocop:enable Metrics/MethodLength

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

      # Use identifier as layer_id id when there is no wxs_identifier.
      # Causes errors in Geoblacklight views.
      def layer_id
        wxs_identifier || identifier
      end

      def private_document
        clean = clean_document(private_document_hash)
        if valid?(clean)
          clean
        else
          schema_errors(clean)
        end
      end

      # Insert special dct references for works with private visibility
      def private_document_hash
        optional = document_hash_optional
        optional[:dct_references_s] = clean_document(private_references).to_json.to_s
        document_hash_required.merge(optional)
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

      def private_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      def public_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end

      # Builds the dct_references hash.
      # @return [Hash] geoblacklight references as a hash
      # rubocop:disable Metrics/MethodLength
      def references
        {
          "http://schema.org/url" => url,
          "http://www.opengis.net/cat/csw/csdgm" => fgdc,
          "http://www.isotc211.org/schemas/2005/gmd/" => iso19139,
          "http://www.loc.gov/mods/v3" => mods,
          "http://schema.org/downloadUrl" => download,
          "http://schema.org/thumbnailUrl" => thumbnail,
          "http://www.opengis.net/def/serviceType/ogc/wms" => wms_path,
          "http://www.opengis.net/def/serviceType/ogc/wfs" => wfs_path,
          "http://iiif.io/api/image" => iiif,
          "http://iiif.io/api/presentation#manifest" => iiif_manifest,
          "http://www.opengis.net/def/serviceType/ogc/wmts" => wmts_path,
          "https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames" => xyz_path
        }
      end
      # rubocop:enable Metrics/MethodLength

      def restricted_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end

      # Returns the geoblacklight rights field based on work visibility.
      # @return [String] geoblacklight access rights
      def rights
        case access_rights
        when public_visibility
          "Public"
        else
          "Restricted"
        end
      end

      # Returns the content of geoblacklight JSON-Schema document.
      # @return [Hash] geoblacklight json schema
      def schema
        JSON.parse(File.read(schema_path))
      end

      # Returns a hash of errors from json schema validation.
      # @return [Hash] json schema validation errors
      def schema_errors(doc)
        { error: JSON::Validator.fully_validate(schema, doc, fragment: "#/definitions/layer") }
      end

      # Returns a path to the geoblackligh schema document
      # @return [String]
      def schema_path
        Rails.root.join("config", "discovery", "geoblacklight-schema.json")
      end

      def build_private_document?
        return true if geom_types.include?("Image") && access_rights == restricted_visibility
        return true if access_rights == private_visibility
        false
      end

      # Validates the geoblacklight document against the json schema.
      # @return [Boolean] is the document valid?
      def valid?(doc)
        JSON::Validator.validate(schema, doc, fragment: "#/definitions/layer")
      end
  end
end
