# frozen_string_literal: true

class TilePath
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def tilejson
    return unless valid?
    "#{tileserver}/#{id}/#{endpoint}/WebMercatorQuad/tilejson.json"
  end

  def wmts
    return unless valid?
    "#{tileserver}/#{id}/#{endpoint}/WebMercatorQuad/WMTSCapabilities.xml"
  end

  def xyz
    return unless valid?
    "#{tileserver}/#{id}/#{endpoint}/tiles/WebMercatorQuad/{z}/{x}/{y}@1x.png"
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
      if mosaic?
        resource.id.to_s.delete("-")
      else
        fs = file_sets.first
        fm = fs.file_metadata.find { |m| m.cloud_uri.present? }
        fm.cloud_uri.gsub(/^.*\/\//, "").split("/")[-2].delete("-")
      end
    end

    def tileserver
      Figgy.config["tileserver"][:url]
    end

    def valid?
      return false unless file_sets.count.positive?
      true
    end

    def mosaic?
      # A mosaic is single service comprised of multiple raster datasets.
      # This tests if there are multiple child raster FileSets.
      return true if raster_file_sets && raster_file_sets.count > 1
      false
    end

    def file_sets
      @file_sets ||= query_service.custom_queries.mosaic_file_sets_for(id: resource.id)
    end

    def query_service
      ChangeSetPersister.default.query_service
    end

    def raster_file_sets
      @raster_file_sets ||= query_service.custom_queries.mosaic_file_sets_for(id: resource.id)
    end
end
