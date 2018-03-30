# frozen_string_literal: true
class PDFGenerator
  class CanvasDownloader
    attr_reader :canvas
    delegate :width, :height, to: :canvas
    def initialize(canvas, quality: 'gray')
      @canvas = canvas
      @quality = quality
    end

    def download
      open(canvas_url, 'rb')
    end

    def layout
      if portrait?
        :portrait
      else
        :landscape
      end
    end

    def quality
      return @quality if ['gray', 'bitonal'].include?(@quality)
      'default'
    end

    def portrait?
      canvas.width <= canvas.height
    end

    private

      def canvas_url
        "#{canvas.url}/full/#{max_width},/0/#{quality}.#{format}"
      end

      def format
        bitonal? ? 'png' : 'jpg'
      end

      def max_dimensions
        { height: (Canvas::LETTER_HEIGHT * scale_factor).round, width: (Canvas::LETTER_WIDTH * scale_factor).round }
      end

      def max_width
        return Canvas::BITONAL_SIZE if bitonal?
        [max_dimensions[:width], canvas.width].min
      end

      def max_height
        return Canvas::BITONAL_SIZE if bitonal?
        [max_dimensions[:height], canvas.height].min
      end

      def scale_factor
        3.0
      end

      def bitonal?
        quality == 'bitonal'
      end
  end
end
