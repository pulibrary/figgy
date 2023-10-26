# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Ogr
      extend ActiveSupport::Concern

      included do
        # Executes a ogr2ogr command. Used to reproject a
        # vector dataset and save the output as a shapefile
        # @param in_path [String] file input path
        # #param options [Hash] creation options
        # @param out_path [String] processor output file path
        def self.reproject(in_path, out_path, options)
          execute "env OGR_ENABLE_PARTIAL_REPROJECTION=YES env SHAPE_ENCODING= ogr2ogr -q "\
                  "-nln #{options[:id]} -f 'ESRI Shapefile' -t_srs #{options[:output_srid]} "\
                  "-preserve_fid '#{out_path}' '#{in_path}'"
        end

        # Executes a ogr2ogr command. Used to reproject a
        # vector dataset and save the output as a flatgeobuff in WGS84
        # @param in_path [String] file input path
        # #param options [Hash] creation options
        # @param out_path [String] processor output file path
        def self.cloud_reproject(in_path, out_path, options)
          execute "env OGR_ENABLE_PARTIAL_REPROJECTION=YES env ogr2ogr -q "\
                  "-nln #{options[:id]} -f FlatGeobuf -t_srs EPSG:4326 "\
                  "-preserve_fid '#{out_path}.fgb' '#{in_path}'"
        end
      end
    end
  end
end
