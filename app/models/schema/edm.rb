# frozen_string_literal: true
##
# Defines the attributes from the Europeana Data Model (EDM)
module Schema
  module EDM
    extend ActiveSupport::Concern

    def self.attributes
      [
        :rights_statement, # http://www.europeana.eu/schemas/edm/rights
      ]
    end

    included do
      EDM.attributes.each do |field|
        attribute field
      end
    end
  end
end
