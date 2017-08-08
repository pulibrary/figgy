# frozen_string_literal: true
##
# Module for the opaquenamespace MODS attributes
module Schema
  module OpaqueMods
    extend ActiveSupport::Concern

    def self.attributes
      [
        :sort_title # http://opaquenamespace.org/ns/mods/titleForSort
      ]
    end

    included do
      OpaqueMods.attributes.each do |field|
        attribute field
      end
    end
  end
end
