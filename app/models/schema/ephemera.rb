# frozen_string_literal: true
##
# Defining the attributes for Ephemera Resources within Plum
module Schema
  module Ephemera
    extend ActiveSupport::Concern

    def self.attributes
      SCHEMA.attributes + RDFS.attributes + Plum::Local.attributes + NFO.attributes + OpaqueMods.attributes + DublinCore.attributes + BIBFRAME.attributes
    end

    included do
      Ephemera.attributes.each do |field|
        attribute field
      end
    end
  end
end
