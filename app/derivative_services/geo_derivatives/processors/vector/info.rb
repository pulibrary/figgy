# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Vector
      class Info
        attr_accessor :doc
        attr_writer :name, :driver

        def initialize(path)
          @doc = ogrinfo(path)
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
            stdout, _stderr, _status = Open3.capture3("ogrinfo -ro -so -al #{path}")
            stdout
          end

          # Given an output string from the ogrinfo command, returns
          # the vector dataset name.
          # @return [String] vector dataset name
          def vector_name
            match = /(?<=Layer name:\s).*?(?=\n)/.match(doc)
            match ? match[0] : ""
          end

          # Given an output string from the ogrinfo command, returns
          # the ogr driver used to read dataset.
          # @return [String] ogr driver name
          def driver_name
            match = /(?<=driver\s`).*?(?=')/.match(doc)
            match ? match[0] : ""
          end

          # Given an output string from the ogrinfo command, returns
          # the vector geometry type.
          # @return [String] vector geom
          def vector_geom
            match = /(?<=Geometry:\s).*?(?=\n)/.match(doc)
            geom = match ? match[0] : ""
            # Transform OGR-style 'Line String' into GeoJSON 'Line'
            geom == "Line String" ? "Line" : geom
          end

          # Given an output string from the ogrinfo command, returns
          # the vector bounding box.
          # @return [Hash] vector bounds
          def vector_bounds
            match = /(?<=Extent:\s).*?(?=\n)/.match(doc)
            extent = match ? match[0] : ""

            # remove parens and spaces, split into array, and assign elements to variables
            w, s, e, n = extent.delete(" ").gsub(")-(", ",").delete("(").delete(")").split(",")
            { north: n.to_f, east: e.to_f, south: s.to_f, west: w.to_f }
          end
      end
    end
  end
end
