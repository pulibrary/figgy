# frozen_string_literal: true
require "pathname"
require "erb"
module Hathi
  class ContentPackage
    # See https://www.hathitrust.org/deposit_guidelines
    attr_reader :resource, :pages, :template, :image_md
    def initialize(resource:)
      @resource = resource
      @image_md = ImageMetadata.new resource: resource
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
