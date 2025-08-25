# frozen_string_literal: true
module GeoDerivatives
  module Processors
    module Vector
      class Base < Hydra::Derivatives::Processors::Processor
        include Hydra::Derivatives::Processors::ShellBasedProcessor
        include GeoDerivatives::Processors::BaseGeoProcessor
        include GeoDerivatives::Processors::Image
        include GeoDerivatives::Processors::Ogr
        include GeoDerivatives::Processors::Gdal
        include GeoDerivatives::Processors::Rendering
        include GeoDerivatives::Processors::Zip
        include GeoDerivatives::Processors::Tippecanoe

        def self.encode(path, options, output_file)
          case options[:label]
          when :thumbnail
            encode_vector(path, output_file, options)
          when :display_vector
            reproject_vector(path, output_file, options)
          when :cloud_vector
            cloud_vector(path, output_file, options)
          end
        end

        def self.cloud_queue
          [:cloud_reproject, :generate_pmtiles]
        end

        # Set of commands to run to encode the vector thumbnail.
        # @return [Array] set of command name symbols
        def self.encode_queue
          [:reproject, :vector_thumbnail, :trim, :center]
        end

        # Set of commands to run to reproject the vector.
        # @return [Array] set of command name symbols
        def self.reproject_queue
          [:reproject, :zip]
        end

        def self.encode_vector(in_path, out_path, options)
          run_commands(in_path, out_path, encode_queue, options)
        end

        def self.reproject_vector(in_path, out_path, options)
          run_commands(in_path, out_path, reproject_queue, options)
        end

        def self.cloud_vector(in_path, out_path, options)
          run_commands(in_path, out_path, cloud_queue, options)
        end

        def encode_file(file_suffix, options)
          temp_file_name = output_file(file_suffix, options[:working_dir])
          self.class.encode(source_path, options, temp_file_name)
          output_file_service.call(File.open(temp_file_name, "rb"), directives)
          File.unlink(temp_file_name)
        end

        def output_file(file_suffix, working_dir)
          Dir::Tmpname.create(["vector_derivative", ".#{file_suffix}"], working_dir) {}
        end
      end
    end
  end
end
