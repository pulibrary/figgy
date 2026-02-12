module GeoDiscovery
  class BaseDocument
    attr_accessor :access_rights, :all_subject, :call_number, :cog_path, :creator,
                  :dct_references, :description, :download, :fgdc, :format,
                  :geom_types, :identifier, :iiif, :iiif_manifest, :iso19139,
                  :issued, :language, :layer_modified, :layer_year, :pmtiles_path, :mods,
                  :held_by, :publisher, :resource_type, :rendered_rights_statement,
                  :slug, :solr_coverage, :source, :spatial, :subject,
                  :suppressed, :temporal, :thumbnail, :title, :url, :wmts_path, :xyz_path


    def to_hash(_args = nil)
      return document unless build_private_document?
      private_document
    end

    def to_json(_args = nil)
      return document.to_json unless build_private_document?
      private_document.to_json
    end

    # Cleans the document hash by removing unused fields.
    # @param [Hash] document hash
    # @return [Hash] cleaned document hash
    def clean_document(hash)
      hash.delete_if do |_k, v|
        v.blank? && v != false
      end
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

      def build_private_document?
        return true if geom_types.include?("Image") && access_rights == restricted_visibility
        return true if access_rights == private_visibility
        false
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

      def private_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end

      def public_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end

      def restricted_visibility
        Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
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

      # Validates the geoblacklight document against the json schema.
      # @return [Boolean] is the document valid?
      def valid?(doc)
        JSON::Validator.validate(schema, doc, fragment: "#/definitions/layer")
      end
  end
end
