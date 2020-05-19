# frozen_string_literal: true
##
# Defining a common superset of attributes for Resources
module Schema
  module Common
    extend ActiveSupport::Concern

    def self.attributes
      Schema::IIIF.attributes +
        Schema::MARCRelators.attributes +
        [
          :import_url, # http://scholarsphere.psu.edu/ns#importUrl
          :label, # info:fedora/fedora-system:def/model#downloadFilename
          :relative_path, # http://scholarsphere.psu.edu/ns#relativePath
          :visibility, # No RDF URI - See hydra-access-controls

          :abstract, # http://purl.org/dc/terms/abstract
          :alternative, # http://purl.org/dc/terms/alternative
          :alternative_title, # http://purl.org/dc/terms/alternative
          :references, # http://purl.org/dc/terms/bibliographicCitation,
          :bibliographic_citation,
          :indexed_by, # http://purl.org/dc/terms/isReferencedBy
          :contents, # http://purl.org/dc/terms/tableOfContents
          :created, # http://purl.org/dc/terms/created
          :date_created, # http://purl.org/dc/terms/created
          :extent, # http://purl.org/dc/terms/extent
          :genre, # http://purl.org/dc/terms/type
          :geo_subject, # http://purl.org/dc/terms/coverage
          :identifier, # http://purl.org/dc/terms/identifier
          :license, # http://purl.org/dc/terms/rights
          :part_of, # http://purl.org/dc/terms/isPartOf
          :replaces, # http://purl.org/dc/terms/replaces
          :resource_type, # http://purl.org/dc/terms/type
          :title, # http://purl.org/dc/terms/title
          :uniform_title, # http://purl.org/dc/elements/1.1/title
          :type, # http://purl.org/dc/terms/type
          :provenance, # http://purl.org/dc/terms/provenance

          :contributor, # http://purl.org/dc/elements/1.1/contributor
          :coverage, # http://purl.org/dc/elements/1.1/coverage
          :creator, # http://purl.org/dc/elements/1.1/creator
          :date, # http://purl.org/dc/elements/1.1/date
          :description, # http://purl.org/dc/elements/1.1/description
          :keyword, # http://purl.org/dc/elements/1.1/relation
          :language, # http://purl.org/dc/elements/1.1/language
          :text_language, # http://purl.org/dc/terms/language
          :local_identifier, # http://purl.org/dc/elements/1.1/identifier
          :publisher, # http://purl.org/dc/elements/1.1/publisher
          :date_published, # http://purl.org/dc/elements/1.1/date_published
          :date_copyright, # http://purl.org/dc/elements/1.1/date_copyright
          :date_issued, # http://purl.org/dc/elements/1.1/date_issued
          :rights_note, # http://purl.org/dc/elements/1.1/rights
          :source, # http://purl.org/dc/elements/1.1/source
          :subject, # http://purl.org/dc/elements/1.1/subject

          :sort_title, # http://opaquenamespace.org/ns/mods/titleForSort
          :rights_statement, # http://www.europeana.eu/schemas/edm/rights
          :portion_note, # http://www.w3.org/2004/02/skos/core#scopeNote
          :binding_note, # http://www.w3.org/2004/02/skos/core#note

          :cartographic_scale, # http://bibframe.org/vocab/cartographicScale
          :edition, # http://id.loc.gov/ontologies/bibframe/editionStatement
          :geographic_origin, # http://id.loc.gov/ontologies/bibframe/originPlace
          :holding_location, # http://bibframe.org/vocab/heldBy
          :source_acquisition, # http://bibframe.org/vocab/immediateAcquisition

          :source_metadata_identifier, # Local
          :source_metadata, # Local
          :source_jsonld, # Local
          :call_number, # Local
          :location, # Local; call number or shelf location
          :barcode, # Local
          :series, # Local
          :ocr_language, # Local
          :pdf_type, # Local
          :container, # Local
          :thumbnail_id, # Local
          :imported_author, # Local
          :rendered_rights_statement, # Local
          :coverage_point, # local, used for latitude / longitude
          :downloadable, # Determines whether or not users can download a resource
          :electronic_locations
        ]
    end

    included do
      Common.attributes.each do |common_attribute|
        attribute common_attribute
      end
      attribute :claimed_by, Valkyrie::Types::String
      attribute :cached_parent_id, Valkyrie::Types::ID
    end
  end
end
