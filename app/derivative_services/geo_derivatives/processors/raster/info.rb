# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Raster
      class Info
        attr_accessor :doc
        attr_writer :min_max, :size

        def initialize(path)
          @doc = gdalinfo(path)
        end

        # Returns raster bounds
        # @return [Hash] bounds
        def bounds
          @bounds = raster_bounds
        end

        # Returns the gdal driver name
        # @return [String] driver name
        def driver
          @driver = driver_name
        end

        # Returns the min and max values for a raster.
        # @return [String] computed min and max values
        def min_max
          @min_max ||= raster_min_max
        end

        # Returns the raster size.
        # @return [Array] raster size
        def size
          @size ||= raster_size
        end

        private

          # Given an output string from the gdalinfo command, returns
          # the gdal driver used to read dataset.
          # @return [String] gdal driver name
          def driver_name
            match = /(?<=Driver:\s).*?(?=\s)/.match(doc)
            match ? match[0] : ""
          end

          ## Converts coordinate in degrees, minutes, seconds to decimal degrees
          #   Example: 74° 25' 55.8" -> 74.43217
          # @param d [String] degrees
          # @param m [String] minutes
          # @param s [String] seconds
          # @return [Float] coordinate in decimal degrees
          def dms_to_dd(d, m, s)
            dd = d.to_f + (m.to_f / 60) + (s.to_f / 3600)

            # Truncate to 6 decimal places
            # https://observablehq.com/@mourner/latitude-and-longitude-precision
            dd.truncate(6)
          end

          ## Extracts lon/lat values from gdal_info corner coordinates string
          #   Example:
          #   (  546945.000, 4662235.000) ( 74d25'55.80"W, 42d 6'45.83"N) ->
          #   [74.432166, 42.11273]
          # @param gdal_string [String] corner corner string from gdal_info
          # @return [Array<Float, Float>] coordinates in decimal degrees
          def extract_coordinates(gdal_string)
            # remove parens and spaces, split into array, and assign elements to variables
            _, _, lon, lat = gdal_string.delete(" ").gsub(")(", ",").delete("(").delete(")").split(",")
            # split coordinate string into degree, minute, second values
            lon = lon.delete("\"W").tr("d", ",").tr("'", ",").split(",")
            lat = lat.delete("\"N").tr("d", ",").tr("'", ",").split(",")

            # Convert to decimal degrees and return
            [dms_to_dd(*lon), dms_to_dd(*lat)]
          end

          # Runs the gdalinfo command and returns the result as a string.
          # @param path [String] path to raster file
          # @return [String] output of gdalinfo
          def gdalinfo(path)
            stdout, _stderr, _status = Open3.capture3("gdalinfo -mm #{path}")
            stdout
          end

          # Given an output string from the gdalinfo command, returns
          # the raster bounding box.
          # @return [Hash] raster bounds
          def raster_bounds
            ul = /(?<=Upper Left\s).*?(?=\n)/.match(doc)
            lr = /(?<=Lower Right\s).*?(?=\n)/.match(doc)
            w, n = extract_coordinates(ul[0])
            e, s = extract_coordinates(lr[0])

            { north: n, east: e, south: s, west: w }
          rescue StandardError
            ""
          end

          # Given an output string from the gdalinfo command, returns
          # a formatted string for the computed min and max values.
          # @return [String] computed min and max values
          def raster_min_max
            match = %r{(?<=Computed Min/Max=).*?(?=\s)}.match(doc)
            match ? match[0].tr(",", " ") : ""
          end

          # Given an output string from the gdalinfo command, returns
          # an array containing the raster width and height as strings.
          # @return [String] raster size
          def raster_size
            match = /(?<=Size is ).*/.match(doc)
            match ? match[0].tr(",", "") : ""
          end
      end
    end
  end
end
