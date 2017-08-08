# frozen_string_literal: true
##
# Defines the attributes from the NEPOMUK File Ontology
module Schema
  module NFO
    extend ActiveSupport::Concern

    def self.attributes
      [
        :page_count # http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#pageCount
      ]
    end

    included do
      NFO.attributes.each do |field|
        attribute field
      end
    end
  end
end
