# frozen_string_literal: true

class TilePath
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def tilejson
    return unless valid?
    "#{tileserver}/#{endpoint}/tilejson.json?id=#{id}"
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
      return false if resource.is_a?(ScannedMap) && resource.decorate.scanned_maps_count <= 1
      true
    end

    def mosaic?
      return true unless resource.is_a?(RasterResource)
      return true if resource.decorate.decorated_raster_resources.count.positive?
      false
    end
end
