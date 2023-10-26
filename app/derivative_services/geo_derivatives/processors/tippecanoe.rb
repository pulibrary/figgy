# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Tippecanoe
      extend ActiveSupport::Concern

      included do
        # Executes a tippecanoe to generate a pmtiles file
        # @param in_path [String] file input path
        # #param options [Hash] creation options
        # @param out_path [String] processor output file path
        def self.generate_pmtiles(in_path, out_path, _options)
          execute "tippecanoe --maximum-tile-features=10000 --no-tile-size-limit " \
            "-zg --coalesce-densest-as-needed --extend-zooms-if-still-dropping -o #{out_path} #{in_path}.fgb"
        end
      end
    end
  end
end
