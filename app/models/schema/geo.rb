# frozen_string_literal: true
##
# Defines attributes for geo resources
module Schema
  module Geo
    extend ActiveSupport::Concern

    def self.attributes
      Common.attributes + [
        :cartographic_projection, # http://bibframe.org/vocab/cartographicProjection
        :held_by, # http://id.loc.gov/ontologies/bibframe/heldBy
        :issued, # http://purl.org/dc/terms/issued
        :spatial, # http://purl.org/dc/terms/spatial
        :temporal # http://purl.org/dc/terms/temporal
      ]
    end

    included do
      Geo.attributes.each do |field|
        attribute field
      end

      # Can be used to override business logic about whether a record is discoverable in GeoBlacklight
      attribute :gbl_suppressed_override, Valkyrie::Types::Bool
      attribute :claimed_by, Valkyrie::Types::String
      attribute :cached_parent_id, Valkyrie::Types::ID
    end
  end
end
