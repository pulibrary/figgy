# frozen_string_literal: true
class PDFGenerator
  class CanvasDownloader
    attr_reader :canvas
    delegate :width, :height, to: :canvas
    def initialize(canvas, quality: "grey")
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
      if @quality == 'gray'
        'gray'
      else
        'default'
      end
    end

    def portrait?
      canvas.width <= canvas.height
    end

    private

      def canvas_url
        "#{canvas.url}/full/#{max_width},#{max_height}/0/#{quality}.#{format}"
      end

      def format
        bitonal? ? 'png' : 'jpg'
      end

      def max_width
        return Canvas::BITONAL_SIZE if bitonal?
        [(Canvas::LETTER_WIDTH * scale_factor).round, canvas.width].min
      end

      def max_height
        return Canvas::BITONAL_SIZE if bitonal?
        [(Canvas::LETTER_HEIGHT * scale_factor).round, canvas.height].min
      end

      def scale_factor
        1.5
      end

      def bitonal?
        quality == 'bitonal'
      end
  end
end
