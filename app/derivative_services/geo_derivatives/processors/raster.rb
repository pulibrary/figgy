# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Raster
      class Processor < Hydra::Derivatives::Processors::Processor
        def process
          raster_processor_class.new(source_path,
                                      directives,
                                      output_file_service: output_file_service).process
        end

        # Returns a raster processor class based on mime type passed in the directives object.
        # @return raster processing class
        def raster_processor_class
          case directives.fetch(:input_format)
          when "text/plain; gdal-format=USGSDEM"
            GeoDerivatives::Processors::Raster::Dem
          when "application/octet-stream; gdal-format=AIG"
            GeoDerivatives::Processors::Raster::Aig
          else
            GeoDerivatives::Processors::Raster::Base
          end
        end
      end
    end
  end
end
