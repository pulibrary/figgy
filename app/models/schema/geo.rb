# frozen_string_literal: true

# Defines attributes for geo resources
module Schema
  module Geo
    extend ActiveSupport::Concern

    def self.attributes
      untyped_attributes + typed_attributes.keys
    end

    def self.typed_attributes
      Common.typed_attributes.merge(
        {
          # Can be used to override business logic about whether a record is discoverable in GeoBlacklight
          gbl_suppressed_override: Valkyrie::Types::Bool,
          # Custom values for overriding auto-generated OGC Web Service properties.
          # Used to build records for manually created GeoServer raster mosaics, for example.
          wms_url: Valkyrie::Types::String,
          wfs_url: Valkyrie::Types::String,
          layer_name: Valkyrie::Types::String
        }
      )
    end

    def self.untyped_attributes
      Common.untyped_attributes + [
        :cartographic_projection, # http://bibframe.org/vocab/cartographicProjection
        :held_by, # http://id.loc.gov/ontologies/bibframe/heldBy
        :issued, # http://purl.org/dc/terms/issued
        :spatial, # http://purl.org/dc/terms/spatial
        :temporal # http://purl.org/dc/terms/temporal
      ]
    end

    included do
      Geo.untyped_attributes.each do |field|
        attribute field
      end

      Geo.typed_attributes.each do |name, type|
        attribute name, type
      end

      attribute :cached_parent_id, Valkyrie::Types::ID.optional
    end
  end
end
