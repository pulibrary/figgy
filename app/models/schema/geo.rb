# frozen_string_literal: true
##
# Defines attributes for geo resources
module Schema
  module Geo
    extend ActiveSupport::Concern

    def self.attributes
      Common.attributes + [
        :provenance, #  http://purl.org/dc/terms/provenance
        :spatial, # http://purl.org/dc/terms/spatial
        :temporal, # http://purl.org/dc/terms/temporal
        :issued # http://purl.org/dc/terms/issued
      ]
    end

    included do
      Geo.attributes.each do |field|
        attribute field
      end
    end
  end
end
