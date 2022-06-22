# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Raster
      class Aig < GeoDerivatives::Processors::Raster::Base
        include GeoDerivatives::Processors::Zip

        def self.encode(path, options, output_file)
          unzip(path, output_file) do |zip_path|
            info = Info.new(zip_path)
            options[:min_max] = info.min_max
            case options[:label]
            when :thumbnail
              encode_raster(zip_path, output_file, options)
            when :display_raster
              reproject_raster(zip_path, output_file, options)
            end
          end
        end

        # Set of commands to run to reproject the AIG.
        # @return [Array] set of command name symbols
        def self.reproject_queue
          [:warp, :translate, :compress]
        end

        # Executes a gdal_translate command to translate a raster
        # format into a different format with a scaling options. This command
        # scales the min and max values of the raster into the 0 to 255 range.
        # Scale is inverted (255 to 0) to create a better visualization.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path
        # @param options [Hash] creation options
        def self.translate(in_path, out_path, options)
          execute "gdal_translate -scale #{options[:min_max]} 255 0 "\
                    "-q -ot Byte -of GTiff \"#{in_path}\" #{out_path}"
        end
      end
    end
  end
end
