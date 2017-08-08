# frozen_string_literal: true
##
# Defines the attributes migrated from Dublin Core
module Schema
  module DublinCore
    extend ActiveSupport::Concern

    def self.attributes
      [
        :title, # http://purl.org/dc/terms/title
        :part_of, # http://purl.org/dc/terms/isPartOf
        :resource_type, # http://purl.org/dc/terms/type
        :creator, # http://purl.org/dc/elements/1.1/creator
        :contributor, # http://purl.org/dc/elements/1.1/contributor
        :description, # http://purl.org/dc/elements/1.1/description
        :keyword, # http://purl.org/dc/elements/1.1/relation
        :coverage, # http://purl.org/dc/elements/1.1/coverage
        :created, # http://purl.org/dc/terms/created
        :date, # http://purl.org/dc/elements/1.1/date
        :source, # http://purl.org/dc/elements/1.1/source
        :extent, # http://purl.org/dc/terms/extent
        :license, # http://purl.org/dc/terms/rights
        :publisher, # http://purl.org/dc/elements/1.1/publisher
        :date_created, # http://purl.org/dc/terms/created
        :subject, # http://purl.org/dc/elements/1.1/subject
        :language, # http://purl.org/dc/elements/1.1/language
        :bibliographic_citation, # http://purl.org/dc/terms/bibliographicCitation
        :abstract, # http://purl.org/dc/terms/abstract
        :alternative, # http://purl.org/dc/terms/alternative
        :identifier, # http://purl.org/dc/terms/identifier
        :local_identifier, # http://purl.org/dc/elements/1.1/identifier
        :replaces, # http://purl.org/dc/terms/replaces
        :contents, # http://purl.org/dc/terms/tableOfContents
        :rights_note, # http://purl.org/dc/elements/1.1/rights
        :geo_subject, # http://purl.org/dc/terms/coverage
        :genre, # http://purl.org/dc/terms/type
        :alternative_title # http://purl.org/dc/terms/alternative
      ]
    end

    included do
      DublinCore.attributes.each do |field|
        attribute field
      end
    end
  end
end
