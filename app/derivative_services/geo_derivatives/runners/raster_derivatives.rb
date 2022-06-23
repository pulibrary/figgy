# frozen_string_literal: true
module GeoDerivatives
  module Runners
    class RasterDerivatives < Hydra::Derivatives::Runner
      def self.processor_class
        GeoDerivatives::Processors::Raster::Processor
      end
    end
  end
end
