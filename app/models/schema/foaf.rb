# frozen_string_literal: true
##
# Retrieve the attributes from Friend of a Friend (FOAF)
module Schema
  module FOAF
    extend ActiveSupport::Concern

    def self.attributes
      [
        :based_near # http://xmlns.com/foaf/0.1/based_near
      ]
    end

    included do
      FOAF.attributes.each do |field|
        attribute field
      end
    end
  end
end
