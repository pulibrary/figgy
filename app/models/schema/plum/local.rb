# frozen_string_literal: true
##
# Defines the attributes local to the Princeton University Library
module Schema
  module Plum
    module Local
      extend ActiveSupport::Concern

      def self.attributes
        [
          :source_metadata_identifier, # Local
          :source_metadata, # Local
          :source_jsonld, # Local
          :call_number, # Local
          :barcode, # Local
          :series, # Local
          :ocr_language, # Local
          :pdf_type, # Local
          :container, # Local
          :thumbnail_id,
          :imported_author,
          :rendered_rights_statement
        ]
      end

      included do
        Local.attributes.each do |field|
          attribute field
        end
      end
    end
  end
end
