# frozen_string_literal: true

##
# Defines the attributes from the IIIF
module Schema
  module IIIF
    extend ActiveSupport::Concern

    def self.attributes
      [
        :nav_date, # http://iiif.io/api/presentation/2#navDate
        :start_canvas, # http://iiif.io/api/presentation/2#hasStartCanvas
        :viewing_direction, # http://iiif.io/api/presentation/2#viewingDirection
        :viewing_hint # http://iiif.io/api/presentation/2#viewingHint
      ]
    end

    included do
      IIIF.attributes.each do |field|
        attribute field
      end
    end
  end
end
