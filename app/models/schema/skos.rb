# frozen_string_literal: true
##
# Defines the attributes for the Simple Knowledge Organization System (SKOS)
module Schema
  module SKOS
    extend ActiveSupport::Concern

    def self.attributes
      [
        :portion_note, # http://www.w3.org/2004/02/skos/core#scopeNote
      ]
    end

    included do
      SKOS.attributes.each do |field|
        attribute field
      end
    end
  end
end
