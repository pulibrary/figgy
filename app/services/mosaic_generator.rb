# frozen_string_literal: true

# A class to wrap a call to cogeo-mosaic
class MosaicGenerator
  attr_reader :output_path, :raster_paths
  # @param output_path [String] where to write the mosaic manifest file
  # @param raster_paths [Array<String>] paths to raster images to compute over
  def initialize(output_path:, raster_paths:)
    @output_path = output_path
    @raster_paths = raster_paths
  end

  def run
    mosaic_command do |command|
      _stdout_str, error_str, status = Open3.capture3(command)
      raise StandardError, error_str unless status.success?
    end

    true
  end

  private

    # need the key to read the images
    def mosaic_command
      temp_file = Tempfile.new
      temp_file.write(raster_paths.join("\n"))
      temp_file.rewind
      yield "#{access_key} #{secret_access_key} LC_ALL=C.UTF-8 LANG=C.UTF-8 cogeo-mosaic create #{temp_file.path} -o #{output_path}"
      temp_file.close
    end

    def access_key
      "AWS_ACCESS_KEY_ID=#{Figgy.config['aws_access_key_id']}"
    end

    def secret_access_key
      "AWS_SECRET_ACCESS_KEY=#{Figgy.config['aws_secret_access_key']}"
    end
end
