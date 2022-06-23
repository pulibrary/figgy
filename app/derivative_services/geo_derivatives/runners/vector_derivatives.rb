# frozen_string_literal: true
module GeoDerivatives
  module Runners
    class VectorDerivatives < Hydra::Derivatives::Runner
      def self.processor_class
        GeoDerivatives::Processors::Vector::Processor
      end
    end
  end
end
