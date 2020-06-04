# frozen_string_literal: true
class PDFGenerator
  class Canvas
    # Letter width/height in points for a PDF.
    LETTER_WIDTH = PDF::Core::PageGeometry::SIZES["LETTER"].first
    LETTER_HEIGHT = PDF::Core::PageGeometry::SIZES["LETTER"].last
    BITONAL_SIZE = 2000

    # Error raised when IIIF Manifests have an invalid structure
    class InvalidIIIFManifestError < StandardError; end

    attr_reader :canvas

    # @param [Hash] canvas
    def initialize(canvas)
      @canvas = canvas
      validate!
    end

    def plain_text_download
      rendering.find do |render|
        render["format"] == "text/plain"
      end || {}
    end

    def ocr_download_url
      plain_text_download["@id"]
    end

    def rendering
      canvas["rendering"] ||= []
    end

    def image
      @image ||= canvas["images"].first
    end

    # Ensure that the IIIF Manifest image has a valid structure
    # @raise [InvalidIIIFManifestError]
    def validate!
      raise(InvalidIIIFManifestError, "IIIF Manifest image does not reference a resource") unless image.key?("resource")
      raise(InvalidIIIFManifestError, "IIIF Manifest image does not specify a width") unless image["resource"].key?("width") && image["resource"]["width"]
      raise(InvalidIIIFManifestError, "IIIF Manifest image does not specify a height") unless image["resource"].key?("height") && image["resource"]["height"]
      raise(InvalidIIIFManifestError, "IIIF Manifest image does not specify a service URL") unless image["resource"].key?("service") && image["resource"]["service"].key?("@id")
    end

    # Access the width for the image
    # @return [Integer]
    def width
      image["resource"]["width"].to_i
    end

    # Access the height for the image
    # @return [Integer]
    def height
      image["resource"]["height"].to_i
    end

    # Access the URL for the IIIF image server
    # @return [String]
    def url
      image["resource"]["service"]["@id"]
    end
  end
end
