# frozen_string_literal: true
module GeoResources
  module GeoDiscovery
    class AbstractDocument
      attr_accessor :identifier, :provenance, :creator, :subject, :spatial, :temporal,
                    :title, :description, :access_rights, :language, :issued,
                    :publisher, :slug, :solr_coverage, :layer_year,
                    :layer_modified, :geom_type, :format, :resource_type, :wxs_identifier,
                    :dct_references, :fgdc, :iso19139, :mods, :download, :url, :thumbnail,
                    :wxs_identifier, :wms_path, :wfs_path, :iiif, :iiif_manifest, :source, :suppressed

      # Cleans the document hash by removing unused fields.
      # @param [Hash] document hash
      # @return [Hash] cleaned document hash
      def clean_document(hash)
        hash.delete_if do |_k, v|
          begin
            v.nil? || v.empty?
          rescue
            false
          end
        end
      end

      def to_hash(_arg)
        raise 'this method should be overriden and return the document as a hash'
      end

      def to_json(_arg)
        raise 'this method should be overriden and return the document as json'
      end

      def to_xml(_arg)
        raise 'this method should be overriden and return the document as xml'
      end
    end
  end
end
