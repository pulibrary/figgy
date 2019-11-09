# frozen_string_literal: true
require "pathname"
require "erb"
require "mini_magick"

module Hathi
  class ContentPackage
    # See https://www.hathitrust.org/deposit_guidelines
    attr_reader :resource, :pages, :template, :image_md
    def initialize(resource:)
      @resource = resource
      @pages = []
      wayfinder = Wayfinder.for(resource)
      wayfinder.members.each_with_index do |fileset, idx|
        pages << Page.new(fileset, (idx + 1).to_s.rjust(8, "0"))
      end
    end

    def id
      if resource.source_metadata_identifier
        resource.source_metadata_identifier.first.to_s
      else
        resource.id.to_s
      end
    end

    def capture_date
      pages.first.capture_date
    end

    def scanner_make
      pages.first.scanner_make
    end

    def scanner_model
      pages.first.scanner_model
    end

    def scanner_user
      %("Princeton University Library: Digital Photography Studio")
    end

    def bitonal?
      pages.first.bitonal?
    end

    def resolution
      pages.first.resolution
    end

    def reading_order
      if resource.viewing_direction
        resource.viewing_direction.first
      else
        %("left-to-right")        
      end
    end

    def template
      path = File.join(File.dirname(__FILE__), "templates/meta.yml.erb")
      File.read(path)
    end

    def metadata
      ERB.new(template).result(binding)
    end

    class Page
      attr_reader :source_page, :name

      def initialize(source_fileset, name)
        @name = name
        @source_page = source_fileset
        original_file = Valkyrie::StorageAdapter.find_by(id: source_page.original_file.file_identifiers.first)
        @original_image = MiniMagick::Image.new(original_file.disk_path)
        derivative_file = Valkyrie::StorageAdapter.find_by(id: source_page.derivative_file.file_identifiers.first)
        @derivative_image = MiniMagick::Image.new(derivative_file.disk_path)
        @properties = @original_image.data["properties"]
      end

      def tiff_path
        metadata = source_page.original_file
        tiff_file = Valkyrie::StorageAdapter.find_by(id: metadata.file_identifiers.first)
        tiff_file.disk_path
      end

      def derivative_path
        file_metadata = source_page.derivative_file
        Valkyrie::StorageAdapter.find_by(id: file_metadata.file_identifiers.first).disk_path
      end

      def capture_date
        @properties["xmp:CreateDate"]
      end

      def scanner_make
        @properties["tiff:make"]
      end

      def scanner_model
        @properties["tiff:model"]
      end

      def bitonal?
        @original_image["%z"] == 1
      end

      def resolution
        @original_image["resolution"].first
      end


      def to_txt
        source_page.ocr_content.first if ocr?
      end

      def to_html
        source_page.hocr_content.first if hocr?
      end

      def ocr?
        source_page.ocr_content
      end

      def hocr?
        source_page.hocr_content
      end
    end
  end
end
