# frozen_string_literal: true
##
# Defines the attributes from BIBFRAME
module Schema
  module BIBFRAME
    extend ActiveSupport::Concern

    def self.attributes
      [
        :cartographic_scale, # http://bibframe.org/vocab/cartographicScale
        :edition, # http://id.loc.gov/ontologies/bibframe/editionStatement
        :geographic_origin, # http://id.loc.gov/ontologies/bibframe/originPlace
        :holding_location # http://bibframe.org/vocab/heldBy
      ]
    end

    included do
      BIBFRAME.attributes.each do |field|
        attribute field
      end
    end
  end
end
