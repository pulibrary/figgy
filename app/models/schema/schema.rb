# frozen_string_literal: true
##
# Defines the attributes for schema.org
module Schema
  module SCHEMA
    extend ActiveSupport::Concern

    def self.attributes
      [
        :height, # http://schema.org/height
        :width # http://schema.org/width
      ]
    end

    included do
      SCHEMA.attributes.each do |field|
        attribute field
      end
    end
  end
end
