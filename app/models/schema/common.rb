# frozen_string_literal: true
##
# Defining a common superset of attributes for Resources
module Schema
  module Common
    extend ActiveSupport::Concern

    def self.attributes
      DublinCore.attributes +
        Schema::IIIF.attributes +
        MARCRelators.attributes +
        [
          :import_url, # http://scholarsphere.psu.edu/ns#importUrl
          :label, # info:fedora/fedora-system:def/model#downloadFilename
          :relative_path, # http://scholarsphere.psu.edu/ns#relativePath
          :visibility, # No RDF URI - See hydra-access-controls

          :sort_title, # http://opaquenamespace.org/ns/mods/titleForSort
          :rights_statement, # http://www.europeana.eu/schemas/edm/rights
          :portion_note, # http://www.w3.org/2004/02/skos/core#scopeNote

          :cartographic_scale, # http://bibframe.org/vocab/cartographicScale
          :edition, # http://id.loc.gov/ontologies/bibframe/editionStatement
          :geographic_origin, # http://id.loc.gov/ontologies/bibframe/originPlace
          :holding_location, # http://bibframe.org/vocab/heldBy

          :source_metadata_identifier, # Local
          :source_metadata, # Local
          :source_jsonld, # Local
          :call_number, # Local
          :barcode, # Local
          :series, # Local
          :ocr_language, # Local
          :pdf_type, # Local
          :container, # Local
          :thumbnail_id, # Local
          :imported_author, # Local
          :rendered_rights_statement # Local
        ]
    end

    included do
      Common.attributes.each do |field|
        attribute field
      end
    end
  end
end
