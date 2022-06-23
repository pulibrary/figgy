# frozen_string_literal: true
require "mini_magick"

module GeoDerivatives
  module Processors
    module Image
      extend ActiveSupport::Concern
      included do
        # Uses imagemagick to resize an image and convert it to the output format.
        # Keeps the aspect ratio of the original image and adds padding to
        # to the output image. The file extension is the output format.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path.
        # @param options [Hash] creation options
        # @option options [String] `:output_size` as "w h" or "wxh"
        def self.convert(in_path, out_path, options)
          size = options[:output_size].tr(" ", "x")
          convert = MiniMagick::Tool::Convert.new(whiny: false)
          convert << in_path
          convert << "-resize"
          convert << size
          convert << "-extent"
          convert << size
          convert << "-background"
          convert << "white"
          convert << "-gravity"
          convert << "center"
          convert << out_path

          # suppress stderr b/c geotiffs return 'unknown field' warnings
          convert.call { |_stdout, _stderr| }
        end

        # Trims extra whitespace.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path.
        # @param options [Hash] creation options
        def self.trim(in_path, out_path, _options)
          MiniMagick::Tool::Convert.new do |convert|
            convert << in_path
            convert << "-trim"
            convert << out_path
          end
        end

        # Centers and pads image.
        # @param in_path [String] file input path
        # @param out_path [String] processor output file path.
        # @param options [Hash] creation options
        def self.center(in_path, out_path, options)
          MiniMagick::Tool::Convert.new do |convert|
            convert << "-size"
            convert << options[:output_size].tr(" ", "x")
            convert << "xc:white"
            convert << in_path
            convert << "-gravity"
            convert << "center"
            convert << "-composite"
            convert << out_path
          end
        end
      end
    end
  end
end
