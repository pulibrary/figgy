# frozen_string_literal: true
##
# Defines the attributes for RDF Schema
module Schema
  module RDFS
    extend ActiveSupport::Concern

    def self.attributes
      [
        :folder_number, # http://www.w3.org/2000/01/rdf-schema#label
        :related_url # http://www.w3.org/2000/01/rdf-schema#seeAlso
      ]
    end

    included do
      RDFS.attributes.each do |field|
        attribute field
      end
    end
  end
end
