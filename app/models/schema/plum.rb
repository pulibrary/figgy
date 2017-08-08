# frozen_string_literal: true
##
# Defines the attributes for all Resources within Plum
module Schema
  module Plum
    extend ActiveSupport::Concern

    def self.attributes
      OpaqueMods.attributes + SKOS.attributes + DublinCore.attributes + EDM.attributes + Local.attributes + BIBFRAME.attributes + Schema::IIIF.attributes + MARCRelators.attributes
    end

    included do
      Plum.attributes.each do |field|
        attribute field
      end
    end
  end
end
