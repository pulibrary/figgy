# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Raster
      class Dem < GeoDerivatives::Processors::Raster::Base
        # Set of commands to run to encode the DEM thumbnail.
        # @return [Array] set of command name symbols
        def self.encode_queue
          [:hillshade, :convert, :trim, :center]
        end

        # Set of commands to run to reproject the DEM.
        # @return [Array] set of command name symbols
        def self.reproject_queue
          [:hillshade, :warp, :compress]
        end

        # Executes a gdal hillshade command. Calculates hillshade
        # on a raster that contains elevation data.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.hillshade(in_path, out_path, _options)
          execute "gdaldem hillshade -q "\
                    "-of GTiff \"#{in_path}\" #{out_path}"
        end
      end
    end
  end
end
