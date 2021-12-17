# frozen_string_literal: true

# A class to wrap a call to cogeo-mosaic
class MosaicGenerator
  attr_reader :output_path, :raster_paths
  # @param resource [RasterResource]
  def initialize(output_path:, raster_paths:)
    @output_path = output_path
    @raster_paths = raster_paths
  end

  def run
    _stdout_str, error_str, status = Open3.capture3(mosaic_command)
    raise StandardError, error_str unless status.success?
    true
  end

  private

    # need the key to read the images
    def mosaic_command
      "echo \"#{raster_paths}\" | #{access_key} #{secret_access_key} LC_ALL=C.UTF-8 LANG=C.UTF-8 cogeo-mosaic create - -o #{output_path}"
    end

    def access_key
      "AWS_ACCESS_KEY_ID=#{Figgy.config['aws_access_key_id']}"
    end

    def secret_access_key
      "AWS_SECRET_ACCESS_KEY=#{Figgy.config['aws_secret_access_key']}"
    end
end
