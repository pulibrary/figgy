# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Vector
      class Info
        attr_accessor :path
        attr_writer :name, :driver

        def initialize(path)
          @path = path
        end

        # Parsed json out from ogrinfo
        # @return [Hash]
        def doc
          @doc ||= begin
                     JSON.parse(ogrinfo(path))
                   rescue
                     {}
                   end
        end

        # Returns the vector dataset name
        # @return [String] dataset name
        def name
          @name = vector_name
        end

        # Returns the ogr driver name
        # @return [String] driver name
        def driver
          @driver = driver_name
        end

        # Returns vector geometry type
        # @return [String] geom
        def geom
          @geom = vector_geom
        end

        # Returns vector bounds
        # @return [String] bounds
        def bounds
          @bounds = vector_bounds
        end

        private

          # Runs the ogrinfo command and returns the result as a string.
          # @param path [String] path to vector file or shapefile directory
          # @return [String] output of ogrinfo
          def ogrinfo(path)
            stdout, stderr, status = Open3.capture3("ogrinfo", "-json", "-ro", "-so", "-al", path.to_s)
            raise(GeoDerivatives::OgrError, stderr) unless status.success?
            stdout
          end

          # Given an output string from the ogrinfo command, returns
          # the vector dataset name.
          # @return [String] vector dataset name
          def vector_name
            doc.dig("layers", 0, "name") || ""
          end

          # Given an output string from the ogrinfo command, returns
          # the ogr driver used to read dataset.
          # @return [String] ogr driver name
          def driver_name
            doc.fetch("driverShortName", "")
          end

          # Given an output string from the ogrinfo command, returns
          # the vector geometry type.
          # @return [String] vector geom
          def vector_geom
            geom = doc.dig("layers", 0, "geometryFields", 0, "type") || ""

            # Transform OGR-style 'Line String' into GeoJSON 'Line'
            # Transform OGR-style '3D Multi Polygon' into GeoJSON 'Polygon'
            if geom == "LineString"
              geom = "Line"
            elsif geom == "3D Multi Polygon"
              geom = "Polygon"
            end

            geom
          end

          # Given an output string from the ogrinfo command, returns
          # the vector bounding box.
          # @return [Hash] vector bounds
          def vector_bounds
            extent = doc.dig("layers", 0, "geometryFields", 0, "extent").map { |c| c.truncate(6) }

            { north: extent[3].to_f, east: extent[2].to_f, south: extent[1].to_f, west: extent[0].to_f }
          end
      end
    end
  end
end
