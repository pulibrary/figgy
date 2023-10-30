# frozen_string_literal: true

module GeoDerivatives
  module Processors
    module Gdal
      extend ActiveSupport::Concern

      included do
        # Executes a gdal_translate command. Used to translate a raster
        # format into a different format. Also used in generating thumbnails
        # from vector data.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.translate(in_path, out_path, _options)
          execute "gdal_translate -q -ot Byte -of GTiff -co TILED=YES -expand rgb -co COMPRESS=DEFLATE \"#{in_path}\" #{out_path}"
        rescue StandardError
          # Try without expanding rgb
          execute "gdal_translate -q -ot Byte -of GTiff -co TILED=YES -co COMPRESS=DEFLATE \"#{in_path}\" #{out_path}"
        end

        # Executes a gdalwarp command. Used to transform a raster
        # from one projection into another.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.warp(in_path, out_path, options)
          execute "gdalwarp -q -t_srs #{options[:output_srid]} "\
                  "#{in_path} #{out_path} -co TILED=YES -co COMPRESS=NONE"
        end

        # Executes a gdal_translate command. Used to compress
        # a previously uncompressed raster.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.compress(in_path, out_path, options)
          execute "gdal_translate -q -ot Byte -a_srs #{options[:output_srid]} "\
                    "#{in_path} #{out_path} -co COMPRESS=JPEG -co JPEG_QUALITY=90"
        end

        # Executes gdaladdo and gdal_translate commands. Used to add internal overviews
        # and then compress a previously uncompressed raster.
        # Output will be a Cloud Optimized GeoTIFF.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.cloud_optimized_geotiff(in_path, out_path, _options)
          system("gdaladdo -q -r average #{in_path} 2 4 8 16 32")
          execute("gdal_translate -q -expand rgb #{in_path} #{out_path} -ot Byte -co TILED=YES "\
                    "-co COMPRESS=LZW -co COPY_SRC_OVERVIEWS=YES")
        rescue StandardError
          # Try without expanding rgb
          execute("gdal_translate -q #{in_path} #{out_path} -ot Byte -co TILED=YES "\
                    "-co COMPRESS=LZW -co COPY_SRC_OVERVIEWS=YES")
        end

        # Executes a gdal_rasterize command. Used to rasterize vector
        # format into raster format.
        # @param in_path [String] file input path
        # #param options [Hash] creation options
        # @param out_path [String] processor output file path
        def self.rasterize(in_path, out_path, options)
          execute "gdal_rasterize -q -burn 0 -init 255 -ot Byte -ts "\
                    "#{options[:output_size]} -of GTiff #{in_path} #{out_path}"
        end
      end
    end
  end
end
