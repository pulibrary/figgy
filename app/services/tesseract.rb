# frozen_string_literal: true
class Tesseract
  class << self
    def languages
      language_output.split("\n")[1..-1].map(&:to_sym).each_with_object({}) do |lang, hsh|
        hsh[lang] = label(lang)
      end
    end

    private

      def label(lang)
        if iso_result(lang)
          iso_result(lang).english_name
        else
          I18n.t("simple_form.options.defaults.ocr_language.#{lang}", default: lang.to_s)
        end
      end

      def iso_result(lang)
        ISO_639.find_by_code(lang.to_s)
      end

      def language_output
        @language_output ||= `tesseract --list-langs 2>&1`
      end
  end
end
