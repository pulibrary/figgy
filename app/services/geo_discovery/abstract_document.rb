# frozen_string_literal: true
# frozen_string_literal: true
module GeoDiscovery
  class AbstractDocument
    attr_accessor :access_rights, :all_subject, :call_number, :cog_path, :creator,
                  :dct_references, :description, :download, :fgdc, :format,
                  :geom_types, :identifier, :iiif, :iiif_manifest, :iso19139,
                  :issued, :language, :layer_modified, :layer_year, :pmtiles_path, :mods,
                  :held_by, :publisher, :resource_type, :rendered_rights_statement,
                  :slug, :solr_coverage, :source, :spatial, :subject,
                  :suppressed, :temporal, :thumbnail, :title, :url, :wmts_path, :xyz_path

    # Cleans the document hash by removing unused fields.
    # @param [Hash] document hash
    # @return [Hash] cleaned document hash
    def clean_document(hash)
      hash.delete_if do |_k, v|
        v.blank? && v != false
      end
    end

    def to_hash(_arg)
      raise "this method should be overriden and return the document as a hash"
    end

    def to_json(_arg)
      raise "this method should be overriden and return the document as json"
    end

    def to_xml(_arg)
      raise "this method should be overriden and return the document as xml"
    end
  end
end
