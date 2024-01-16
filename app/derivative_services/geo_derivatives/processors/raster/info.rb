# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Raster
      class Info
        attr_accessor :path
        attr_writer :min_max, :size

        def initialize(path)
          @path = path
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

        # Parsed json out from gdalinfo
        # @return [Hash]
        def doc
          @doc ||= JSON.parse(gdalinfo(path))
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
            doc.fetch("driverShortName", "")
          end

          # Runs the gdalinfo command and returns the result as a string.
          # @param path [String] path to raster file
          # @return [String] output of gdalinfo
          def gdalinfo(path)
            stdout, stderr, status = Open3.capture3("gdalinfo", "-json", "-mm", path.to_s)
            raise(GeoDerivatives::GdalError, stderr) unless status.success?
            stdout
          end

          # Given an output string from the gdalinfo command, returns
          # the raster bounding box.
          # @return [Hash] raster bounds
          def raster_bounds
            extent = doc["wgs84Extent"]["coordinates"][0]
            longitudes = extent.map { |c| c.first.truncate(6) }
            latitudes = extent.map { |c| c.last.truncate(6) }
            n = latitudes.max
            e = longitudes.max
            s = latitudes.min
            w = longitudes.min

            { north: n, east: e, south: s, west: w }
          rescue StandardError
            ""
          end

          # Given an output string from the gdalinfo command, returns
          # a formatted string for the computed min and max values.
          # @return [String] computed min and max values
          def raster_min_max
            min = doc.dig("bands", 0, "min")
            max = doc.dig("bands", 0, "max")
            return "" unless min && max
            "#{min} #{max}"
          end

          # Given an output string from the gdalinfo command, returns
          # an array containing the raster width and height as strings.
          # @return [String] raster size
          def raster_size
            size = doc["size"]
            return "" unless size
            "#{size[0]} #{size[1]}"
          end
      end
    end
  end
end
