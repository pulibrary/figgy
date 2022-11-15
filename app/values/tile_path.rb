# frozen_string_literal: true

class TilePath
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def tilejson
    return unless valid?
    # Our tile service doesn't know how to resolve IDs for development, so just
    # put the direct URL to S3 here.
    if Rails.env.development?
      "#{tileserver}/#{endpoint}/tilejson.json?url=#{TileMetadataService.new(resource: resource).path}"
    else
      "#{tileserver}/#{endpoint}/tilejson.json?id=#{id}"
    end
  end

  def wmts
    return unless valid?
    "#{tileserver}/#{endpoint}/WMTSCapabilities.xml?id=#{id}"
  end

  def xyz
    return unless valid?
    "#{tileserver}/#{endpoint}/tiles/WebMercatorQuad/{z}/{x}/{y}@1x.png?id=#{id}"
  end

  private

    def endpoint
      if mosaic?
        "mosaicjson"
      else
        "cog"
      end
    end

    def id
      resource.id.to_s.delete("-")
    end

    def tileserver
      Figgy.config["tileserver"][:url]
    end

    def valid?
      file_count = resource.decorate.try(:mosaic_file_count)
      return false unless file_count&.positive?
      true
    end

    def mosaic?
      return true if resource.is_a?(RasterResource) && resource.decorate.raster_resources_count > 1
      return true if raster_file_sets.count > 1
      false
    end

    def query_service
      ChangeSetPersister.default.query_service
    end

    def raster_file_sets
      @raster_file_sets ||= query_service.custom_queries.mosaic_file_sets_for(id: resource.id)
    end
end
