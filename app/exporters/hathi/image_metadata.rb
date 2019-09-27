# frozen_string_literal: true
require "mini_magick"

module Hathi
  class ImageMetadata
    attr_reader :resource, :repr_image
    def initialize(resource:)
      @resource = resource
      wayfinder = Wayfinder.for(resource)
      page = wayfinder.members.first
      metadata = page.original_file
      tiff_file = Valkyrie::StorageAdapter.find_by(id: metadata.file_identifiers.first)
      @repr_image = MiniMagick::Image.new(tiff_file.disk_path)
    end

    def capture_date
      repr_image.data["properties"]["tiff:timestamp"]
    end

    def scanner_make
      repr_image.data["properties"]["tiff:make"]
    end

    def scanner_model
      repr_image.data["properties"]["tiff:model"]
    end

    def scanner_user
      "Princeton University Library: Digital Photography Studio"
    end

    def bitonal?
      repr_image["%z"] == 1
    end

    def resolution
      repr_image["resolution"].first
    end

    def scanning_order
      "left_to_right"
    end

    def reading_order
      "left_to_right"
    end

    def pagedata; end
  end
end
