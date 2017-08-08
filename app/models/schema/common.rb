# frozen_string_literal: true
##
# Defining a common superset of attributes for Resources
module Schema
  module Common
    extend ActiveSupport::Concern

    def self.attributes
      Plum.attributes + [
        :import_url, # http://scholarsphere.psu.edu/ns#importUrl
        :label, # info:fedora/fedora-system:def/model#downloadFilename
        :relative_path, # http://scholarsphere.psu.edu/ns#relativePath
        :visibility # No RDF URI - See hydra-access-controls
      ]
    end

    included do
      Common.attributes.each do |field|
        attribute field
      end
    end
  end
end
