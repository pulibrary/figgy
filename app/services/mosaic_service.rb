# frozen_string_literal: true

# This class provides mosaic manifest uris, and calls out to the
# MosaicGenerator as needed
class MosaicService
  class Error < StandardError; end
  attr_reader :resource
  # @param resource [RasterResource]
  def initialize(resource:)
    @resource = resource.decorate
  end

  def generate
    raise Error if raster_file_sets.empty?
    mosaic["visibility"] = visibility
    mosaic
  end

  private

    def mosaic
      @mosaic ||= MosaicGenerator.new(raster_paths: raster_paths).run
    end

    def visibility
      resource.model.visibility&.first&.to_s
    end

    def raster_file_sets
      @raster_file_sets ||= resource.decorated_raster_resources.map { |r| r.decorate.geo_members }.flatten
    end

    def raster_paths
      raster_file_sets.map do |fs|
        fs.file_metadata.map(&:cloud_uri)
      end.flatten.compact.join("\n")
    end
end
