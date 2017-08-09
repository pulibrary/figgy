# frozen_string_literal: true
##
# Defines the attributes migrated from Dublin Core
module Schema
  module DublinCore
    extend ActiveSupport::Concern

    def self.attributes
      [
        :abstract, # http://purl.org/dc/terms/abstract
        :alternative, # http://purl.org/dc/terms/alternative
        :alternative_title, # http://purl.org/dc/terms/alternative
        :bibliographic_citation, # http://purl.org/dc/terms/bibliographicCitation
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
        :type, # http://purl.org/dc/terms/type

        :contributor, # http://purl.org/dc/elements/1.1/contributor
        :coverage, # http://purl.org/dc/elements/1.1/coverage
        :creator, # http://purl.org/dc/elements/1.1/creator
        :date, # http://purl.org/dc/elements/1.1/date
        :description, # http://purl.org/dc/elements/1.1/description
        :keyword, # http://purl.org/dc/elements/1.1/relation
        :language, # http://purl.org/dc/elements/1.1/language
        :local_identifier, # http://purl.org/dc/elements/1.1/identifier
        :publisher, # http://purl.org/dc/elements/1.1/publisher
        :rights_note, # http://purl.org/dc/elements/1.1/rights
        :source, # http://purl.org/dc/elements/1.1/source
        :subject # http://purl.org/dc/elements/1.1/subject
      ]
    end

    included do
      DublinCore.attributes.each do |field|
        attribute field
      end
    end
  end
end
