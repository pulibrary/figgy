# frozen_string_literal: true
require "mini_magick"

module Hathi
  # Extrapolates image data for entire resource from the first image
  class ImageMetadata
    attr_reader :resource, :original_image
    def initialize(resource:)
      @resource = resource
      wayfinder = Wayfinder.for(resource)
      page = ContentPackage::Page.new(wayfinder.members.first, "representative page")
      # page = wayfinder.members.first

      @original_image = MiniMagick::Image.new(page.tiff_path)
      @derivative_image = MiniMagick::Image.new(page.derivative_path)
    end

    def capture_date
      original_image.data["properties"]["xmp:CreateDate"]
    end

    def scanner_make
      original_image.data["properties"]["tiff:make"]
    end

    def scanner_model
      original_image.data["properties"]["tiff:model"]
    end

    def scanner_user
      %("Princeton University Library: Digital Photography Studio")
    end

    def bitonal?
      original_image["%z"] == 1
    end

    def resolution
      original_image["resolution"].first
    end

    def scanning_order
      "left-to-right"
    end

    def reading_order
      "left-to-right"
    end

    def pagedata; end
  end
end
