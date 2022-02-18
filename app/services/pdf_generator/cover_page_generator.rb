# frozen_string_literal: true

class PDFGenerator
  class CoverPageGenerator
    attr_reader :pdf_generator
    delegate :resource, to: :pdf_generator
    def initialize(pdf_generator)
      @pdf_generator = pdf_generator
    end

    def header(prawn_document, header, size: 16)
      Array(header).each do |text|
        prawn_document.move_down 10
        display_text(prawn_document, text, size: size, styles: [:bold], inline_format: true)
      end
      prawn_document.stroke do
        prawn_document.horizontal_rule
      end
      prawn_document.move_down 10
    end

    def text(prawn_document, text)
      Array(text).each do |value|
        display_text(prawn_document, value)
      end
      prawn_document.move_down 5
    end

    def apply(prawn_document)
      noto_cjk_b = Rails.root.join("app", "assets", "fonts", "NotoSansCJK", "NotoSansCJKtc-Bold.ttf")
      noto_cjk_r = Rails.root.join("app", "assets", "fonts", "NotoSansCJK", "NotoSansCJKtc-Regular.ttf")
      noto_ara_b = Rails.root.join("app", "assets", "fonts", "NotoNaskhArabic", "NotoNaskhArabic-Bold.ttf")
      noto_ara_r = Rails.root.join("app", "assets", "fonts", "NotoNaskhArabic", "NotoNaskhArabic-Regular.ttf")
      amiri_b = Rails.root.join("app", "assets", "fonts", "amiri", "amiri-bold.ttf")
      amiri_r = Rails.root.join("app", "assets", "fonts", "amiri", "amiri-regular.ttf")
      dejavu = Rails.root.join("app", "assets", "fonts", "Dejavu", "DejaVuSerif-webfont.ttf")

      prawn_document.font_families.update(
        "amiri" => {normal: amiri_r, italic: amiri_r, bold: amiri_b, bold_italic: amiri_b},
        "noto_cjk" => {normal: noto_cjk_r, italic: noto_cjk_r, bold: noto_cjk_b, bold_italic: noto_cjk_b},
        "noto_ara" => {normal: noto_ara_r, italic: noto_ara_r, bold: noto_ara_b, bold_italic: noto_ara_b},
        "dejavu" => {normal: dejavu, italic: dejavu, bold: dejavu, bold_italic: dejavu}
      )
      prawn_document.fallback_fonts(["noto_cjk", "noto_ara", "amiri", "dejavu"])
      prawn_document.font("dejavu")

      prawn_document.bounding_box([15, Canvas::LETTER_HEIGHT - 15], width: Canvas::LETTER_WIDTH - 30, height: Canvas::LETTER_HEIGHT - 30) do
        prawn_document.image Rails.root.join("app", "assets", "images", "pul_logo_long.png").to_s, position: :center, width: Canvas::LETTER_WIDTH - 30
        prawn_document.stroke_color "000000"
        prawn_document.move_down(20)
        header(prawn_document, resource.title, size: 24)
        resource.rights_statement.each do |statement|
          text(prawn_document, rights_statement_label(statement))
          rights_statement_text(statement).split("\n").flat_map { |x| x.split("<br/>") }.each do |line|
            text(prawn_document, line)
          end
        end
        prawn_document.move_down 20

        header(prawn_document, "Princeton University Library Disclaimer")
        prawn_document.text I18n.t("works.show.attributes.rights_statement.boilerplate"), inline_format: true
        prawn_document.move_down 20

        header(prawn_document, "Citation Information")
        if resource.respond_to?(:primary_imported_metadata) && resource.try(:change_set) != "simple"
          creator = resource.primary_imported_metadata.creator
          edition = resource.primary_imported_metadata.edition
          extent = resource.primary_imported_metadata.extent
          description = resource.primary_imported_metadata.description
          call_number = resource.primary_imported_metadata.call_number
        else
          creator = resource.creator if resource.respond_to?(:creator)
          edition = resource.edition if resource.respond_to?(:edition)
          extent = resource.extent if resource.respond_to?(:extent)
          description = resource.description if resource.respond_to?(:description)
          call_number = resource.call_number if resource.respond_to?(:call_number)
        end

        text(prawn_document, creator)
        text(prawn_document, resource.title)
        text(prawn_document, edition)
        text(prawn_document, extent)
        text(prawn_document, description)
        text(prawn_document, call_number)
        # collection name (from EAD) ? not in jsonld

        header(prawn_document, "Contact Information")
        text = (resource.try(:holding_location) || []).map { |x| holding_location_text(x) }.join("")
        prawn_document.text text, inline_format: true
        prawn_document.move_down 20

        header(prawn_document, "Download Information")
        prawn_document.text "Date Rendered: #{Time.current.strftime("%Y-%m-%d %I:%M:%S %p %Z")}"
        resource_link = if resource.decorate.public_readable_state? && resource.identifier
          identifier = Ark.new(resource.identifier.first)
          identifier.uri
        else
          IdentifierService.url_for(resource)
        end

        prawn_document.text "Available Online at: <u><a href='#{resource_link}'>#{resource_link}</a></u>", inline_format: true
      end
    end

    private

      def holding_location_text(holding_location)
        ControlledVocabulary.for(:holding_location).find(holding_location).label
      end

      def rights_statement_label(statement)
        ControlledVocabulary.for(:rights_statement).find(statement).label
      end

      def rights_statement_text(statement)
        ControlledVocabulary.for(:rights_statement).find(statement).definition
      end

      def display_text(prawn_document, text, options = {})
        bidi_text = dir_split(text).map do |s|
          s = s.connect_arabic_letters.gsub("\uFEDF\uFE8E", "\uFEFB") if s.dir == "rtl" && lang_is_arabic?
          s.dir == "rtl" ? s.reverse : s
        end.join(" ")
        options = options.merge(align: :right, kerning: true) if bidi_text.dir == "rtl"
        prawn_document.text bidi_text, options
      end

      def lang_is_arabic?
        resource.respond_to?(:primary_imported_metadata) &&
          resource.primary_imported_metadata.language &&
          resource.primary_imported_metadata.language.first &&
          resource.primary_imported_metadata.language.first == "ara"
      end

      def dir_split(s)
        chunks = []
        s.to_s.split(/\s/).each do |word|
          chunks << (chunks.last && chunks.last.dir == word.dir ? "#{chunks.pop} #{word}" : word)
        end
        chunks
      end
  end
end
