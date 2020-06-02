# frozen_string_literal: true
class PDFGenerator
  class CanvasDownloader
    attr_reader :canvas
    delegate :width, :height, :ocr_download_url, to: :canvas
    def initialize(canvas, quality: "gray")
      @canvas = canvas
      @quality = quality
    end

    # Download the PDF by opening the stream with OpenURI using the read-only and binary modes
    # @return [File]
    def download
      open(download_url, "rb")
    end

    # The server isn't authorized to download from itself through HTTP. Instead,
    # just grab it from the database.
    def ocr_content
      return "" unless ocr_download_url.present?
      ocr_fileset_id = ocr_download_url.gsub(/.*file_sets\//, "").gsub("/text", "")
      file_set = Valkyrie.config.metadata_adapter.query_service.find_by(id: ocr_fileset_id)
      Array.wrap(file_set.ocr_content).first
    end

    def layout
      if portrait?
        :portrait
      else
        :landscape
      end
    end

    def quality
      return @quality if ["gray", "bitonal"].include?(@quality)
      "default"
    end

    def portrait?
      canvas.width <= canvas.height
    end

    def download_url
      "#{canvas.url}/full/#{max_width},/0/#{quality}.#{format}"
    end

    private

      def format
        bitonal? ? "png" : "jpg"
      end

      def max_dimensions
        { height: (Canvas::LETTER_HEIGHT * scale_factor).round, width: (Canvas::LETTER_WIDTH * scale_factor).round }
      end

      def max_width
        return Canvas::BITONAL_SIZE if bitonal?
        [max_dimensions[:width], canvas.width].min
      end

      def scale_factor
        2.0
      end

      def bitonal?
        quality == "bitonal"
      end
  end
end
