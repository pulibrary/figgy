# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Vector
      class Shapefile < GeoDerivatives::Processors::Vector::Base
        include GeoDerivatives::Processors::Zip

        def self.encode(path, options, output_file)
          unzip(path, output_file) do |zip_path|
            case options[:label]
            when :thumbnail
              encode_vector(zip_path, output_file, options)
            when :display_vector
              reproject_vector(zip_path, output_file, options)
            end
          end
        end
      end
    end
  end
end
