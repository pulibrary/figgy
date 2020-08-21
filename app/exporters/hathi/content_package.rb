# frozen_string_literal: true
require "pathname"
require "erb"
require "mini_magick"

module Hathi
  class ContentPackage
    # See https://www.hathitrust.org/deposit_guidelines
    attr_reader :resource, :pages, :template
    def initialize(resource:)
      @resource = resource
      @pages = []
      wayfinder = Wayfinder.for(resource)
      wayfinder.members.each_with_index do |fileset, idx|
        pages << DerivativePage.new(fileset, (idx + 1).to_s.rjust(8, "0"))
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
      "Princeton University Library: Digital Photography Studio"
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
        "left-to-right"
      end
    end

    def metadata
      md = {}
      md["capture_date"] = capture_date
      md["scanner_make"] = scanner_make
      md["scanner_model"] = scanner_model
      md["scanner_user"] = scanner_user
      md["reading_order"] = reading_order
      md
    end

    class Page
      def initialize(fileset, basename)
        @basename = basename
        @fileset = fileset
        original_file = Valkyrie::StorageAdapter.find_by(id: @fileset.original_file.file_identifiers.first)
        @original_image = MiniMagick::Image.new(original_file.disk_path)
        @properties = @original_image.data["properties"]
      end

      def image_filename
        extension = image_file.mime_type.first.split("/").last
        @basename + "." + extension
      end

      def ocr_filename
        @basename + ".txt"
      end

      def hocr_filename
        @basename + ".html"
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
        @fileset.ocr_content.first if ocr?
      end

      def to_html
        @fileset.hocr_content.first if hocr?
      end

      def ocr?
        @fileset.ocr_content
      end

      def hocr?
        @fileset.hocr_content
      end
    end

    class OriginalPage < Page
      def image_file
        @fileset.original_file
      end
    end

    class DerivativePage < Page
      def image_file
        jp2_derivative
      end

      def path_to_file
        @path_to_file ||= ephemeral_change_set_persister.storage_adapter.find_by(id: jp2_derivative.file_identifiers.first).disk_path
      end

      def jp2_derivative
        @jp2_derivative ||=
          begin
            ephemeral_change_set_persister.metadata_adapter.persister.save(resource: @fileset)
            Jp2DerivativeService.new(id: @fileset.id, change_set_persister: ephemeral_change_set_persister).create_derivatives
            fileset = ephemeral_change_set_persister.metadata_adapter.query_service.find_by(id: @fileset.id)
            fileset.jp2_derivative
          end
      end

      def ephemeral_change_set_persister
        @csp ||=
          ChangeSetPersister.new(
            metadata_adapter: Valkyrie::Persistence::Memory::MetadataAdapter.new,
            storage_adapter: Valkyrie::Storage::Memory.new
          )
      end
    end
  end
end
