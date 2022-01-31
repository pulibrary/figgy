# frozen_string_literal: true

class TileService
  attr_reader :resource
  def initialize(resource)
    @resource = resource
  end

  def tilejson_path
    return unless valid?
    "#{tileserver}/mosaicjson/tilejson.json?id=#{resource.id}"
  end

  private

    def tileserver
      Figgy.config["tileserver"][:url]
    end

    def valid?
      file_count = resource.decorate.try(:mosaic_file_count)
      return false unless file_count&.positive?
      true
    end
end
